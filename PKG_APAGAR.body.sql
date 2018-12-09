create or replace PACKAGE BODY PKG_APAGAR AS

    CURSOR C_DEPENDENCIA_PELA_FK (
        P_FK_OWNER        ALL_TAB_COLS.OWNER%TYPE,
        P_FK_TABLE_NAME   ALL_TAB_COLS.TABLE_NAME%TYPE,
        P_FK_NAME         ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE
    ) IS
    SELECT
        PK.OWNER        AS PK_OWNER,
        PK.TABLE_NAME   PK_TABLE_NAME,
        FK.OWNER        FK_OWNER,
        FK.TABLE_NAME   FK_TABLE_NAME,
        LISTAGG('''' || FK_COL.TABLE_NAME || '.' || FK_COL.COLUMN_NAME || '=' || '''||' || PK_COL.TABLE_NAME || '.' || PK_COL.COLUMN_NAME
        ,
                '||'' AND ''||') WITHIN GROUP(
            ORDER BY
                FK_COL.POSITION
        ) AS CONDICAO_WHERE
    FROM
        ALL_CONSTRAINTS FK
        JOIN ALL_CONS_COLUMNS FK_COL ON FK_COL.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
                                        AND FK_COL.OWNER = FK.OWNER
        JOIN ALL_CONSTRAINTS PK ON PK.CONSTRAINT_NAME = FK.R_CONSTRAINT_NAME
                                   AND PK.OWNER = FK.R_OWNER
        JOIN ALL_CONS_COLUMNS PK_COL ON PK_COL.CONSTRAINT_NAME = PK.CONSTRAINT_NAME
                                        AND PK_COL.OWNER = PK.OWNER
                                        AND PK_COL.POSITION = FK_COL.POSITION
    WHERE
        FK.CONSTRAINT_TYPE = 'R'
        AND FK.OWNER = UPPER(P_FK_OWNER)
        AND FK.TABLE_NAME = UPPER(P_FK_TABLE_NAME)
        AND FK.CONSTRAINT_NAME = UPPER(P_FK_NAME)
    GROUP BY
        FK.OWNER,
        FK.TABLE_NAME,
        FK.CONSTRAINT_NAME,
        PK.OWNER,
        PK.TABLE_NAME;

    FUNCTION SELECIONA_WHERE_PELA_FK (
        P_FK_OWNER        ALL_TAB_COLS.OWNER%TYPE,
        P_FK_TABLE_NAME   ALL_TAB_COLS.TABLE_NAME%TYPE,
        P_FK_NAME         ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE,
        P_WHERE           VARCHAR
    ) RETURN CLOB IS
        V_SQL           CLOB;
        V_DEPENDENCIA   C_DEPENDENCIA_PELA_FK%ROWTYPE;
    BEGIN
        OPEN C_DEPENDENCIA_PELA_FK(
            P_FK_OWNER,
            P_FK_TABLE_NAME,
            P_FK_NAME
        );
        FETCH C_DEPENDENCIA_PELA_FK INTO V_DEPENDENCIA;
        CLOSE C_DEPENDENCIA_PELA_FK;
        V_SQL := 'SELECT ' || V_DEPENDENCIA.CONDICAO_WHERE;
        V_SQL := V_SQL || ' FROM ' || V_DEPENDENCIA.PK_OWNER || '.' || V_DEPENDENCIA.PK_TABLE_NAME;

        V_SQL := V_SQL || ' WHERE ' || P_WHERE;
        RETURN V_SQL;
    END;

    FUNCTION CONSTRUIR_WHERE_PELA_FK (
        P_FK_OWNER        ALL_TAB_COLS.OWNER%TYPE,
        P_FK_TABLE_NAME   ALL_TAB_COLS.TABLE_NAME%TYPE,
        P_FK_NAME         ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE,
        P_WHERE           VARCHAR
    ) RETURN CLOB IS
        V_SQL     CLOB;
        V_WHERE   CLOB;
    BEGIN
        V_SQL := SELECIONA_WHERE_PELA_FK(
            P_FK_OWNER,
            P_FK_TABLE_NAME,
            P_FK_NAME,
            P_WHERE
        );
        EXECUTE IMMEDIATE V_SQL
        INTO V_WHERE;
        RETURN V_WHERE;
    END;

    FUNCTION APAGAR (
        P_OWNER        ALL_TAB_COLS.OWNER%TYPE,
        P_TABLE_NAME   ALL_TAB_COLS.TABLE_NAME%TYPE,
        P_WHERE        VARCHAR
    ) RETURN CLOB IS
        V_SQL   CLOB;
    BEGIN
        V_SQL := 'DELETE FROM ';
        V_SQL := V_SQL || P_OWNER || '.' || P_TABLE_NAME;
        V_SQL := V_SQL || ' WHERE ' || P_WHERE;
        V_SQL := V_SQL || ';';
        RETURN V_SQL;
    END;

    FUNCTION APAGAR_EM_CASCATA (
        P_OWNER        ALL_TAB_COLS.OWNER%TYPE,
        P_TABLE_NAME   ALL_TAB_COLS.TABLE_NAME%TYPE,
        P_WHERE        VARCHAR
    ) RETURN CLOB IS

        V_SQL     CLOB;
        V_WHERE   CLOB;
        CURSOR C_DEPENDENTES (
            P_OWNER        ALL_TAB_COLS.OWNER%TYPE,
            P_TABLE_NAME   ALL_TAB_COLS.TABLE_NAME%TYPE
        ) IS
        SELECT
            FK.OWNER             FK_OWNER,
            FK.TABLE_NAME        FK_TABLE_NAME,
            FK.CONSTRAINT_NAME   FK_NAME
        FROM
            ALL_CONSTRAINTS FK
            JOIN ALL_CONS_COLUMNS FK_COL ON FK_COL.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
                                            AND FK_COL.OWNER = FK.OWNER
            JOIN ALL_CONSTRAINTS PK ON PK.CONSTRAINT_NAME = FK.R_CONSTRAINT_NAME
                                       AND PK.OWNER = FK.R_OWNER
            JOIN ALL_CONS_COLUMNS PK_COL ON PK_COL.CONSTRAINT_NAME = PK.CONSTRAINT_NAME
                                            AND PK_COL.OWNER = PK.OWNER
                                            AND PK_COL.POSITION = FK_COL.POSITION
        WHERE
            FK.CONSTRAINT_TYPE = 'R'
            AND PK.OWNER = UPPER(P_OWNER)
            AND PK.TABLE_NAME = UPPER(P_TABLE_NAME)
        GROUP BY
            FK.OWNER,
            FK.TABLE_NAME,
            FK.CONSTRAINT_NAME,
            PK.OWNER,
            PK.TABLE_NAME;

    BEGIN
        DBMS_OUTPUT.PUT_LINE(P_OWNER || '.' || P_TABLE_NAME);
        FOR R_DEPENDENTES IN C_DEPENDENTES(
            P_OWNER,
            P_TABLE_NAME
        ) LOOP
            V_WHERE := CONSTRUIR_WHERE_PELA_FK(
                R_DEPENDENTES.FK_OWNER,
                R_DEPENDENTES.FK_TABLE_NAME,
                R_DEPENDENTES.FK_NAME,
                P_WHERE
            );

            V_SQL := V_SQL || APAGAR_EM_CASCATA(
                R_DEPENDENTES.FK_OWNER,
                R_DEPENDENTES.FK_TABLE_NAME,
                V_WHERE
            );

        END LOOP;

        V_SQL := V_SQL || APAGAR(
            P_OWNER,
            P_TABLE_NAME,
            P_WHERE
        );
        RETURN V_SQL;
    END;

END PKG_APAGAR;