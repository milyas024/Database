CREATE OR REPLACE FUNCTION GET_Monthly_Peak_Demand(pMeterNo  in  Number  ,
                                   
                                   PdateKeyNo date
                                   )

RETURN NUMBER IS
RESULT NUMBER;

vMonthly_Peak_Demand number(16,2);
--vHeading varchar2(20);
--vDate Date;

vAveragePrice number(10,4);

vFaceValue fund.face_value%type;


begin

     vUnits := 0;
     vAmount := 0;
     vAveragePrice := 0;
   select MAX(F.DEMMAND_AMT) INTO vMonthly_Peak_Demand from IB_INTERVAL_FACT f where f.METER_KEY_NB= pMeterNo  and f.METER_READ_DT_KEY_NB=  PdateKeyNo;



    result :=vMonthly_Peak_Demand;
--    result := vAmount;
    return result;
end GET_Monthly_Peak_Demand;
