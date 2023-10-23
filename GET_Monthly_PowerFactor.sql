CREATE OR REPLACE FUNCTION GET_Monthly_PowerFactor(pMeterNo  in  Number  ,

                                   PdateKeyNo date
                                   )

RETURN NUMBER IS
RESULT NUMBER;

 vMonthly_PowerFactor number(16,2);
--vHeading varchar2(20);
--vDate Date;

/*vAveragePrice number(10,4);

vFaceValue fund.face_value%type;*/


begin

   select  INTV_DAY_AMT / KVA_DAY_AMT *100 INTO vMonthly_PowerFactor from IB_INTERVAL_FACT_V2 f where f.METER_KEY_NB= pMeterNo  and f.METER_READ_DT_KEY_NB=  PdateKeyNo;



    result :=vMonthly_PowerFactor;
--    result := vAmount;
    return result;
end GET_Monthly_PowerFactor;
