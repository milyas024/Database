CREATE OR REPLACE FUNCTION GET_AVERAGE_PRICE (pFundCode in fund.fund_code%type,
                                   pFolioNumber in unit_account.folio_number%type,
                                   pDate date
                                   )

RETURN NUMBER IS
RESULT NUMBER;

vUnits payment_detail.units_issued%type;
vAmount number(16,2);
--vHeading varchar2(20);
--vDate Date;

vAveragePrice number(10,4);
--vTempResult number;

vFaceValue fund.face_value%type;

/*
  zulfi:
  1. 05-07-2006: to include the impact of account transfer units.
  2. 03-02-2007: to include the impact of fund transfer units.


*/

begin

     vUnits := 0;
     vAmount := 0;
     vAveragePrice := 0;
     select f.face_value into vFaceValue from fund f where f.fund_code = pFundCode;


for transactions in
(
    select *
--    into vUnits,vAmount,vHeading,vDate
    from
    (
     select 3 pri, sum(pd.units_issued) a,sum(nvl(pd.received_amount,pd.amount)) b ,'ASALE' c,pd.gl_date  d
     from unit_sale us, payment_detail pd
     where us.payment_id = pd.payment_id
     and us.post = 1
     and pd.management_status = 1
     and pd.voucher_no is not null
     and pd.gl_date <= pDate
     and us.fund_code = pFundCode
     and us.folio_number = pFolioNumber
     group by pd.gl_date
     union all
     select 1 pri,sum(ub.units) a, 0 b, 'ZBonus' c, ub.bonus_date d
     from unit_bonus ub
     where ub.fund_code = pFundCode
     and ub.folio_number = pFolioNumber
     and ub.bonus_date <= pDate
     group by ub.bonus_date
     union all
     select 2 pri, sum(a),sum(b),'BREDEMPTION' c,d from
     (select ur.uncertified_quantity a ,0 b ,'BREDEMPTION' c, ur.redemption_date d
     from unit_redemption ur
     where ur.post = 1
     and ur.voucher_no is not null
     and ur.redemption_date <= pDate
     and ur.fund_code = pFundCode
     and ur.folio_number = pFolioNumber
     union all
     select urd.quantity a ,0 b ,'BREDEMPTION' c ,ur.redemption_date d
     from unit_redemption ur, unit_redemption_detail urd, unit_certificate uc
     where ur.redemption_id = urd.redemption_id
     and urd.certificate_id = uc.certificate_id
     and uc.status_code in ('RC','CN')
     and ur.post = 1
     and urd.voucher_no is not null
     and ur.redemption_date <= pDate
     and ur.fund_code = pFundCode
     and ur.folio_number = pFolioNumber
     )
     group by d
     union all
     select 3, sum(a),sum(b), 'CACCOUNTTRANSFERIN' c,d from
     (
     select ut.quantity a, 0 b, 'CACCOUNTTRANSFERIN' c,ut.transfer_date d
     from unit_transfer ut
     where ut.post = 1
     and ut.processed = 1
     and ut.to_folio_no = pFolioNumber
     and ut.to_fund_code = ut.from_fund_code -- account trasnfer
     and ut.from_fund_code = pFundCode
     and ut.transfer_date <= pDate
     union all
     select utd.quantity,0,'CACCOUNTTRANSFERIN',ut.transfer_date
     from unit_transfer ut, unit_transfer_detail utd
     where ut.transfer_id = utd.transfer_id
     and ut.post = 1
     and ut.processed = 1
     and ut.to_fund_code = ut.from_fund_code -- account transfer
     and ut.to_folio_no = pFolioNumber
     and ut.from_fund_code = pFundCode
     and ut.transfer_date <= pDate
     )
     group by d
     union all
     select 2, sum(a),sum(b),'DACCOUNTTRANSFEROUT' c,d from
     (
     select ut.quantity a, 0 b, 'DACCOUNTTRANSFEROUT' c,ut.transfer_date d
     from unit_transfer ut
     where ut.post = 1
     and ut.processed = 1
     and ut.from_folio_no = pFolioNumber
     and ut.to_fund_code = ut.from_fund_code -- account trasnfer
     and ut.from_fund_code = pFundCode
     and ut.transfer_date <= pDate
     union all
     select utd.quantity,0,'DACCOUNTTRANSFEROUT',ut.transfer_date
     from unit_transfer ut, unit_transfer_detail utd
     where ut.transfer_id = utd.transfer_id
     and ut.post = 1
     and ut.processed = 1
     and ut.to_fund_code = ut.from_fund_code -- account transfer
     and ut.from_folio_no = pFolioNumber
     and ut.from_fund_code = pFundCode
     and ut.transfer_date <= pDate
     )
     group by d
     union all
     select 3, sum(a) a,sum(b) b,'EFUNDTRANSFERIN' c,d from
     (
     select ut.to_quantity a, (ut.to_quantity*ut.t_price) b, 'EFUNDTRANSFERIN' c,ut.transfer_date d
     from unit_transfer ut
     where ut.post = 1
     and ut.from_folio_no = pFolioNumber
     and ut.to_fund_code <> ut.from_fund_code -- fund trasnfer in
     and ut.to_fund_code = pFundCode
     and ut.transfer_date <= pDate
     union all
     select ucr.quantity a,(ucr.quantity*ut.t_price) b,'EFUNDTRANSFERIN',ut.transfer_date
     from unit_transfer ut, unit_certificate_request ucr
     where ut.transfer_id = ucr.transfer_id
     and ut.post = 1
     and ut.to_fund_code <> ut.from_fund_code -- fund transfer in
     and ut.from_folio_no = pFolioNumber
     and ut.to_fund_code = pFundCode
     and ut.transfer_date <= pDate
     )
     group by d
     union all
     select 2, sum(a) a,sum(b) b,'FFUNDTRANSFEROUT' c,d from
     (
     select ut.quantity a, (ut.quantity*ut.f_price) b, 'FFUNDTRANSFEROUT' c,ut.transfer_date d
     from unit_transfer ut
     where ut.post = 1
     and ut.from_folio_no = pFolioNumber
     and ut.to_fund_code <> ut.from_fund_code -- fund trasnfer
     and ut.from_fund_code = pFundCode
     and ut.transfer_date <= pDate
     union all
     select utd.quantity a,(utd.quantity*ut.t_price) b,'FFUNDTRANSFEROUT',ut.transfer_date
     from unit_transfer ut, unit_transfer_detail utd
     where ut.transfer_id = utd.transfer_id
     and ut.post = 1
     and ut.to_fund_code <> ut.from_fund_code -- fund transfer
     and ut.from_folio_no = pFolioNumber
     and ut.from_fund_code = pFundCode
     and ut.transfer_date <= pDate
     )
     group by d
     ) /* outer block */
     order by d,pri asc
)
loop

    if transactions.c = 'ASALE' then

       vAmount := trunc(vAmount + nvl(transactions.b,0),2);
       vUnits := vUnits + nvl(transactions.a,0);

       if vUnits > 0 then
              vAveragePrice := (vAmount / vUnits);
       end if;

    end if;

    if transactions.c = 'BREDEMPTION' then


       vUnits := vUnits - nvl(transactions.a,0);
       vAmount := trunc(vUnits * Round(vAveragePrice,4),2);

       if vUnits > 0 then
              vAveragePrice := vAmount / vUnits;
       end if;

        if vUnits <= 0 or vAmount <= 0  then
          vUnits := 0 ;
          vAmount := 0;
          vAveragePrice := 0;
        end if;

      end if;

      if transactions.c = 'CACCOUNTTRANSFERIN' then

            vAmount := vAmount +  (nvl(transactions.a,0) * vFaceValue);
            vUnits := vUnits + nvl(transactions.a,0);

            if vUnits > 0 then
               vAveragePrice := get_price_method(vAmount / vUnits,pFundCode);
            end if;

      end if;

      if transactions.c = 'DACCOUNTTRANSFEROUT' then

            vAmount := vAmount -  (nvl(transactions.a,0) * vFaceValue);
            vUnits := vUnits - nvl(transactions.a,0);

            if vUnits > 0 then
               vAveragePrice := get_price_method(vAmount / vUnits,pFundCode);
            end if;

            if vUnits <= 0 or vAmount <= 0  then

                vUnits := 0 ;
                vAmount := 0;
                vAveragePrice := 0;

            end if;

      end if;

      if transactions.c = 'EFUNDTRANSFERIN' then

            vAmount := vAmount +  (nvl(transactions.b,0));
            vUnits := vUnits + nvl(transactions.a,0);

            if vUnits > 0 then
               vAveragePrice := get_price_method(vAmount / vUnits,pFundCode);
            end if;

            if vUnits <= 0 or vAmount <= 0  then

                vUnits := 0 ;
                vAmount := 0;
                vAveragePrice := 0;

            end if;

      end if;

      if transactions.c = 'FFUNDTRANSFEROUT' then

            vUnits := vUnits - nvl(transactions.a,0);
            vAmount := trunc(vUnits * Round(vAveragePrice,4),2);

            if vUnits > 0 then
               vAveragePrice := vAmount / vUnits;
            end if;

            if vUnits <= 0 or vAmount <= 0  then

                vUnits := 0 ;
                vAmount := 0;
                vAveragePrice := 0;

            end if;

      end if;

      if transactions.c = 'ZBonus' then

            --vAmount := vAmount -  (nvl(transactions.a,0) * vFaceValue);
            vUnits := vUnits + nvl(transactions.a,0);

            if vUnits > 0 then
               vAveragePrice := Round(vAmount / vUnits,4);
            end if;

            if vUnits <= 0 or vAmount <= 0  then

                vUnits := 0 ;
                vAmount := 0;
                vAveragePrice := 0;

            end if;

      end if;

   /* dbms_output.put_line('********************************************');
    dbms_output.put_line('TRANSACTION : '||transactions.c);
    dbms_output.put_line('DATE        : '||transactions.d);
    dbms_output.put_line('UNITS       : '||transactions.a);
    dbms_output.put_line('AMOUNT      : '||transactions.b);
    dbms_output.put_line('');
    dbms_output.put_line('TOTAL UNITS : '||vUnits);
    dbms_output.put_line('TOTAL AMT   : '||vAmount);
    dbms_output.put_line('AVG PRICE   : '||vAveragePrice);
    dbms_output.put_line('AVG PRICE Rounded  : '|| get_price_method(vAveragePrice,pfundCode));*/

end loop;

    result := get_price_method(vAveragePrice,pfundCode);
--    result := vAmount;
    return result;
end GET_AVERAGE_PRICE;
/
