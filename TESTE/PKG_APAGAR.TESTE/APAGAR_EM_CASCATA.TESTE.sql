DECLARE
  P_OWNER VARCHAR2(128) := 'IMPORTACAO';
  P_TABLE_NAME VARCHAR2(128) := 'A';
  P_WHERE VARCHAR2(200) := 'A.A1 = 1';
  v_Return CLOB;
BEGIN

  UTIL_TESTE.LIMPAR_TABELAS;

  insert into A(ID_A1,ID_A2,A1) values(1,1,1);
  insert into A(ID_A1,ID_A2,A1) values(1,2,1);
  insert into B(ID_B1,ID_A1,ID_A2,B1) values(1,1,1,1);
  insert into B(ID_B1,ID_A1,ID_A2,B1) values(2,1,1,1);
  insert into B(ID_B1,ID_A1,ID_A2,B1) values(3,1,2,1);

  v_Return := PKG_APAGAR.APAGAR_EM_CASCATA(
    P_OWNER => P_OWNER,
    P_TABLE_NAME => P_TABLE_NAME,
    P_WHERE => P_WHERE
  );
  
  DBMS_OUTPUT.PUT_LINE('v_Return = ' || v_Return);
  
  EXECUTE IMMEDIATE 'BEGIN '|| V_RETURN || 'END;';
  
  FOR R IN (SELECT 1 FROM A WHERE A.A1 = 1) LOOP
    RAISE_APPLICATION_ERROR(-20001,'');
  END LOOP;
  
  ROLLBACK;
END;
