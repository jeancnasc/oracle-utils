create or replace PACKAGE PKG_APAGAR AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */
    FUNCTION APAGAR (
        P_OWNER        ALL_TAB_COLS.OWNER%TYPE,
        P_TABLE_NAME   ALL_TAB_COLS.TABLE_NAME%TYPE,
        P_WHERE        VARCHAR
    ) RETURN CLOB;

    FUNCTION APAGAR_EM_CASCATA (
        P_OWNER        ALL_TAB_COLS.OWNER%TYPE,
        P_TABLE_NAME   ALL_TAB_COLS.TABLE_NAME%TYPE,
        P_WHERE        VARCHAR
    ) RETURN CLOB;

END PKG_APAGAR;