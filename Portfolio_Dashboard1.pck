CREATE OR REPLACE PACKAGE Portfolio_Dashboard1 IS

  PROCEDURE Dividend_Receivable( vFUND_CODE varchar2);

  PROCEDURE InflowStatementData( PFUND_CODE varchar2);

  PROCEDURE PortfolioStatementData(dTransdate date, vFUND_CODE varchar2);

  
  PROCEDURE PopulateEquitySecurities(dTransdate date, vFUND_CODE varchar2,dTransdate1 date);
  PROCEDURE EQUITY_SECTOR_ALLOCATION(dTransdate date, vFUND_CODE varchar2 );
  PROCEDURE FinancedData(Pdate date , vFUND_CODE varchar2);
  PROCEDURE PopulateFixedIncomeSecurities(dTransdate date, vFUND_CODE varchar2);
    PROCEDURE TrialData(Pdate date , vFUND_CODE varchar2);

end Portfolio_Dashboard1;
/
CREATE OR REPLACE PACKAGE BODY Portfolio_Dashboard1 IS

  PROCEDURE Dividend_Receivable( vFUND_CODE varchar2) AS
    v_bank_balance number;
  BEGIN

    FOR ALL_TRANS IN (

                      select  g.gl_voucher_no,g.gl_form_date,g.gl_book_type,g.fund_code,d.amount ,d.dc, d.narration,
                      d.cost_centre

                        from gl_equity_accounts d,gl_forms g

                        where g.gl_voucher_no=d.gl_voucher_no
                        and g.fund_code=vFUND_CODE

                        and d.dc='D'
                         and d.gl_glmf_code='1020502010101'
                      )

     LOOP
      BEGIN
        insert into temp_dividend_receivable
          (gl_voucher_no,
           gl_voucher_date,
           voucher_type,
           description,
           cost_centre,
           checque_no,
           bill_no,
           amount)
        values
          (all_trans.gl_voucher_no,
          all_trans.gl_form_date ,
           all_trans.gl_book_type,
           all_trans.narration,
           all_trans.cost_centre,
           '0',
           '0',
           all_trans.amount);

      exception
        when others then
          dbms_output.put_line('Error: ' || SQLERRM);
      END;
    end loop;

    commit;

  end Dividend_Receivable;

  PROCEDURE InflowStatementData (PFUND_CODE varchar2) AS
    v_bank_balance number;
  BEGIN
    FOR ALL_TRANS IN (

     select G.GL_FORM_DATE,G.GL_VOUCHER_NO,G.GL_FORM_NO,G.GL_BOOK_TYPE,D.COST_CENTRE,D.CHEQUE_NO,D.INVOICE_NO ,'ISSUED IN CASH' narration,d.amount ,'Inflow' investmentType from gl_forms g,gl_journal_det d

      where d.gl_voucher_no=g.gl_voucher_no
      and g.fund_code= PFUND_CODE
      and d.gl_glmf_code='2010101010201'
      and d.dc='C'

      UNION ALL

     select  G.GL_FORM_DATE,G.GL_VOUCHER_NO,G.GL_FORM_NO,G.GL_BOOK_TYPE,D.COST_CENTRE,D.CHEQUE_NO,D.INVOICE_NO ,'ISSUED IN CASH' narration,-d.amount, 'Outflow' investmentType from gl_forms g,gl_journal_det d

      where d.gl_voucher_no=g.gl_voucher_no
      and g.fund_code=PFUND_CODE
      and d.gl_glmf_code='2010101010201'
      and d.dc='D'

)

     LOOP
      BEGIN
        insert into temp_inflowstatementdata
          (gl_voucher_no,
           gl_voucher_date,
           voucher_type,
           description,
           cost_centre,
           checque_no,
           bill_no,
           amount,
           INVESTMENTTYPE)
        values
          (ALL_TRANS.GL_VOUCHER_NO,
          ALL_TRANS.GL_FORM_DATE,
           ALL_TRANS.GL_BOOK_TYPE,
           ALL_TRANS.NARRATION,
          ALL_TRANS.COST_CENTRE,
          ALL_TRANS.CHEQUE_NO,
           ALL_TRANS.INVOICE_NO,
           all_trans.amount,
           ALL_TRANS.INVESTMENTTYPE);

      exception
        when others then
          dbms_output.put_line('Error: ' || SQLERRM);
      END;
    end loop;




    commit;
  end InflowStatementData;

  PROCEDURE PortfolioStatementData(dTransdate date, vFUND_CODE varchar2) AS
    v_bank_balance number;
  BEGIN




     FOR ALL_TRANS IN (

                      select d.gl_voucher_no, d.amount, d.narration
                        from gl_equity_accounts d
                       where lower(d.narration) like '%issued in cash%')

     LOOP
      BEGIN
        insert into temp_inflowstatementdata
          (gl_voucher_no,
           gl_voucher_date,
           voucher_type,
           description,
           cost_centre,
           checque_no,
           bill_no,
           amount)
        values
          (all_trans.gl_voucher_no,
           dTransdate,
           'ETB',
           all_trans.narration,
           '0',
           '0',
           '0',
           all_trans.amount);

      exception
        when others then
          dbms_output.put_line('Error: ' || SQLERRM);
      END;
    end loop;

    commit;

  end PortfolioStatementData;
   
   PROCEDURE PopulateEquitySecurities(dTransdate date, vFUND_CODE varchar2, dTransdate1 date) AS
    v_bank_balance number;

  BEGIN


delete from temp_marketablesecurities t  where t.fund_code=vFUND_CODE  and t.findate=dTransdate;

   FOR ALL_TRANS IN (
  select ep.price_date,ROUND(ep.hft_historical_value/ep.hft_volume,2)  avgCostShare, ep.hft_volume*em.close_rate marketValue, em.close_rate , ep.symbol ,
  '' type,ep.hft_historical_value cost ,ep.hft_mark_to_mkt_value caryingcost ,(ep.hft_volume*em.close_rate-ep.hft_historical_value) unrealizedGain, '' scriptPerofMktValue,'' marketValuePerNetAsset, (select f.fund_code from fund f where f.fund_code=ep.fund_code) Fund,EP.HFT_VOLUME volume,'' buySell
   from equity_portfolio ep, equity_market em
 where ep.fund_code =vFUND_CODE 
 /* and ep.price_date='31-Jan-2021'*/
   and ep.price_date=em.price_date
   and ep.symbol=em.symbol

   and ep.price_date between dTransdate  and dTransdate1)

     LOOP
      BEGIN
    insert into temp_marketablesecurities
  (avgcostshare,
   buysell,
   marketrateshare,
   marketvalperofnetasset,
   marketvalue,
   script,
   fundname,
   scriptwtperofmktvalue,
   shares,
   unrealizedgainloss,
   type,
   cost,
   fund_code,
   findate,
   CARYING_COST)
values
  (ALL_TRANS.AVGCOSTSHARE,
   ALL_TRANS.Buysell,
   
   
    ALL_TRANS.CLOSE_RATE,
    ALL_TRANS.MARKETVALUEPERNETASSET,
    ALL_TRANS.MARKETVALUE,
    ALL_TRANS.Symbol,
    ALL_TRANS.FUND,
    ALL_TRANS.SCRIPTPEROFMKTVALUE,
    ALL_TRANS.VOLUME,
    ALL_TRANS.UNREALIZEDGAIN,
    ALL_TRANS.TYPE,
    ALL_TRANS.COST,
    vFUND_CODE,
    ALL_TRANS.PRICE_DATE,
     ALL_TRANS.CARYINGCOST
    
    );

      exception
        when others then
          dbms_output.put_line('Error: ' || SQLERRM);
      END;
    end loop;


  end PopulateEquitySecurities;
  
    PROCEDURE EQUITY_SECTOR_ALLOCATION(dTransdate date, vFUND_CODE varchar2) AS
    v_bank_balance number;
  BEGIN
  /*
    DELETE FROM equity_sector_allocation SA
     WHERE SA.FUND_CODE = vFUND_CODE
       AND SA.TRANS_DATE = dTransdate;*/
/*  delete from equity_sector_allocation e where e.fund_code=vFUND_CODE and e.fund_code=dTransdate;*/
    FOR ALL_TRANS IN (
                      
                      select sector_name, Sectors ,price_date
                        from (select sec.sector_name sector_name,ep.price_date, 
                                      Round(sum(nvl((ep.hft_volume * em.close_rate),0) /
                                                ( select nvl(d.amount,0) 
   from temp_financeddata d where d.fund_code='00039' and d.description like '%Total Asset%' AND D.FINDATE=ep.price_date) * 100),
                                            2) Sectors
                                 from equity_portfolio ep,
                                      equity_market    em,
                                      security         se,
                                      sector           sec
                                where ep.fund_code = vFUND_CODE
                                  and ep.symbol = se.symbol
                                  and se.sector_code = sec.sector_code
                                  /*and ep.price_date=dTransdate*/
                                   and ep.price_date between '14-sep-2023' and '13-oct-2023'
                                  and ep.symbol = em.symbol
                                  and ep.price_date = em.price_date
                                   and em.market_type!=-1
                                  AND EM.ST_EX_CODE!=-1
                                group by sec.sector_name,ep.price_date
                                order by Sectors desc
                               
                               ))
    
     LOOP
      BEGIN
        insert into equity_sector_allocation
          (fund_code, sector_name, sector_percentage, trans_date)
        values
          (vFUND_CODE,
           ALL_TRANS.SECTOR_NAME,
           ALL_TRANS.SECTORS,
          ALL_TRANS.PRICE_DATE );
      
      exception
        when others then
          dbms_output.put_line('Error: ' || SQLERRM);
      END;
    end loop;
 
   
    
  
    /*select sum(c.sector_percentage)
      into v_bank_balance
      from equity_sector_allocation c
     where c.fund_code = vFUND_CODE
       and c.trans_date = dTransdate;
    v_bank_balance := 100 - v_bank_balance;
    insert into equity_sector_allocation
      (fund_code, sector_name, sector_percentage, trans_date)
    values
      (vFUND_CODE, 'Bank Balance & Others', v_bank_balance, dTransdate);
  
    commit;*/
  END EQUITY_SECTOR_ALLOCATION;

  PROCEDURE FinancedData(Pdate DATE, vFUND_CODE varchar2) AS
  /*  v_bank_balance number;*/
 

  
 n integer := 0;
 result number;

 financialID number:=1;
 startGLCode varchar2(50):=1;
 endGLCode  varchar2(50):=5050101010101;
 openTrial number:=1;
 zeroBal number:=0;
 StartDate date;
 vDescription varchar2(100);
 nPrevMonth number:=0;
 nCurrMonth number:=0;
 nPrevMonthWAPDA number:=0;
 nCurrMonthWAPDA number:=0;


 nPrevMonthTDR number:=0;
 nCurrMonthTDR number:=0;
 nPrevMonthIJ number:=0;
 nCurrMonthIJ number:=0;
 nPrevMonthCSUKUK number:=0;
 nCurrMonthCSUKUK number:=0;

 nPrevMontAsset number:=0;
 nCurrMonthAsset number:=0;

 nCurrMonthDebAmt number:=0;
 nCurrMonthCreAmt number:=0;
 bStatus boolean:= False;

 vFundCode varchar2(10);
 vSymbolIF varchar2(10);
 vSymbolISF varchar2(10);
 vSymbolCF varchar2(10);
 vSymbolIDSF varchar2(10);
 vOthers varchar2(3) := '99';
 A_DATE DATE:='6-oct-2023';
begin
 delete from temp_financeddata m where m.fund_code=vFUND_CODE and m.findate=A_DATE;
 
  WHILE (A_DATE<=Pdate)loop
/*for all_funds in ( select f.fund_code,f.fund_short_name from fund f where f.active=1 and f.fund_code=1)*/
 TRIAL_BALANCE_TEST(financialID, A_DATE, A_DATE,startGLCode,endGLCode,openTrial,zeroBal,vFUND_CODE);


 FOR all_investment in ( 

select 'CAPITAL GAIN/LOSS GOVERMENT SECURITIES' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'5010103' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('5010103'))
     
     
          
     union all
     
     select 'INTEREST INCOME ACCRUAL-TDR' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'50201020101' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('50201020101'))
     
     union all
     
     select 'REALIZED (GAIN)/LOSS ON FUTURE SECURITIES' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'5010105010101' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('5010105010101'))
     
     union all
     
     select 'UNREALIZED GAIN/LOSS ON FUTURE EQUITIES' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'501030104' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('501030104'))
     
       union all
     
     select 'UNREALIZED GAIN/LOSS ON FUTURE EQUITIES' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'501030104' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('501030104'))
     
     
       union all
     
     select 'INITIAL INVESTMENT' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'2010101010201' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('2010101010201'))
     
     
      union all
     
     select 'EXPENSES' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'4' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('4'))
         union all
     
     select 'REALIZED (GAIN)/LOSS)' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'50101' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('50101'))
       union all
     
     select 'DIVIDEND INCOME)' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'5010201010101' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('5010201010101'))
     union all

select 'UNREALISED GAIN LOSS GOVT SEC.(TFC/SUK)' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'5010301020102' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('5010301020102'))
     
     
     
     union all
     
     
     select 'Units' Description ,(select nav_report_util.CALC_TOTAL_UNITS( A_DATE-1,'00028') +nav_report_util.SOLD_UNITS_FOR_THE_DAY(A_DATE ,'00028')-
     nav_report_util.REDEMED_UNITS_FOR_THE_DAY(A_DATE ,'00028') FROM dual)total_amount,'1' gl_code,'From NAV Report' gl_head  from dual

     
    union all
    select 'UNREALISED GAIN LOSS GOVT SEC. TBILLS' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'5010301030101' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('5010301030101'))
     
         union all
    select 'UNREALISED GAIN LOSS GOVT SEC. PIB' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'5010301030102' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('5010301030102'))
      
      union all
    select 'NET INTEREST INCOME' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'502' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('502')) 
     
           union all
    select 'INCOME OF TFC' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'5020201020101' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('5020201020101'))
     
                union all
    select 'INTEREST INCOME ON COI' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'5020401010101' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('5020401010101'))  
     
     
       union all
    select 'INCOME OF GOVT.SEC. TBILLS Commercial paper' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'5020301010101' gl_code,'Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('5020301010101'))
     
       union all
    select 'INCOME OF GOVT.SEC.TBILLS' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'5020301010103' gl_code,' Financed By' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('5020301010103'))
     
          union all
    select 'COUPON RECEIVABLE SUKUK/ TFC' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020403010102' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020403010102'))
     
        union all
    select 'INTEREST INCOME RECEIVABLE' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'10204' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('10204'))
     
     union all
    select 'INVESTMENT IN TERM DEPOSIT RECEIPT' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'10202030101' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('10202030101'))
     
       union all
    select 'BANK BALANCES' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'10202' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('10202'))
     
     
   union all
    select 'INVESTMENT IN DEBT SECURITIES-HFT' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020103' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020103'))
     
       union all
       
    select 'INVESTMENT IN Tbills' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'10201040101' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('10201040101'))
     
     
      union all
    select 'INVESTMENT IN PIB' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'10201070101' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('10201070101'))
     
/*       union all
    select 'INVESTMENT IN SUKUK' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'102010301' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('102010301'))
     */
   /*   union all
    select 'ACCRUED INCOME OF TFC/SUKUK' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020403010102' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020403010102'))*/
     
           union all
    select 'ACCRUED INCOME OF PIB' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020101010101' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020404020101'))
     
     
           union all
    select 'DIVIDEND RECEIVABLE' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020502010101' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020502010101'))
     
    union all
    select 'MANAGEMENT FEE PAYABLE' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'3020301010101' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('3020301010101'))
     
        union all
    select 'OTHER PAYABLE' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'3020406010101' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('3020406010101'))
     
        /*union all
        
        
            select 'ISSUED IN CASH' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'2010101010201' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('2010101010201'))*/
     
      union all
   
    select 'Total Asset' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1'))
     
   
      union all

     
     
            select 'OTHER ASSETS' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'10205' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('10205'))
     
    union all
         select 'Receivable/Payable Equity Sec' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020301010101' gl_code,'NetAssets' gl_head


       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020301010101'))
     
        union all
         select 'Receivable against Redemption of Debt Sec' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020304010101' gl_code,'NetAssets' gl_head

     from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020304010101'))
     
        union all
      select 'Receivable against Redemption of Govt. Sec' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020304020101' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020304020101'))
     
         union all
      select 'Trustee Fee' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'3020301020102' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('3020301020102'))
     
         union all
      select 'Sales Tax on Trustee Fee' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'3020302010604' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('3020302010604'))
     
         union all
      select 'Brokerage on Equity' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'3020406060101' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('3020406060101'))
     
              union all
      select 'CVT' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'3020406060102' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('3020406060102'))
     
       union all
      select 'FED on Brokerage' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'3020406060103' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('3020406060103'))
     
           union all
      select 'Brokerage on Debt Sec' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020301040101' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020301040101'))
     
             union all
      select 'Brokerage on Govt. Sec' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020301050101' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020301050101'))
     
     
         union all
      select 'Receivable /(Payable)Debt &Govt. Sec' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020302' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020302'))
     
            union all
      select 'WHT on Profit' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020501010204' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020501010204'))
     
             union all
      select 'WHT on Profit' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020501010301' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020501010301'))
     
               union all
      select 'WHT on Dividend' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020501010302' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020501010302'))
     
             union all
      select 'OTHER RECEIVABLE' Description, max(gl_glmf_updr)-max(gl_glmf_upcr) total_amount,'1020506010101' gl_code,'NetAssets' gl_head

       from (select a.gl_glmf_updr,a.gl_glmf_upcr,a.gl_glmf_code from
     tb a where a.gl_glmf_code in
     ('1020506010101'))
     
     
     
     )


     loop

 insert into temp_financeddata
  (
  FUND_CODE,
  FINDATE,
  number_of_shares,
   description,
   percent_of_nav,
   symbol,
   total_investmentpercent,
   amount)
values
  (vFUND_CODE,
  A_DATE,
  '',
 all_investment.description,
   '',
   all_investment.gl_head,
   '',
 all_investment.total_amount);



     end loop;
         A_DATE:=A_DATE+1;
         
      end loop;



commit;



result:=1;
/*return result;*/
 end FinancedData;
   PROCEDURE  PopulateFixedIncomeSecurities(dTransdate date, vFUND_CODE varchar2) AS
    v_bank_balance number;
  BEGIN




     FOR ALL_TRANS IN (

        
         select c.fund_code,
       (select s.scheme_name
          from scheme s
         where s.scheme_code = c.scheme_code) Scheme_Name,
         C.SCHEME_CODE,
         'TFC' Scheme_Type,
       c.face_value,
       c.coupon_rate,
       c.yield purchase_yield,
       c.transacted_amount cost,
       k.rate*C.QUANTITY  MARKET_value,
       C.QUANTITY,
       c.scheme_maturity_date,
       C.TRANS_DATE,
       c.price PKRV,
      ( k.rate*C.QUANTITY)-(c.transacted_amount)Unrealized_Gain_Loss,
      DECODE( C.BUY_OR_SELL,'B', 'Purchase','SELL')type
  from fis_contract c, scheme s ,fis_market_rates k
 where c.fund_code = vFUND_CODE
 and c.scheme_code=s.scheme_code
  and s.scheme_code=k.scheme_code
 and k.price_date=c.trans_date

 and s.scheme_type_code='TF'
 and c.trans_date between dTransdate and dTransdate
 



union all 

        select c.fund_code,
       (select s.scheme_name
          from scheme s
         where s.scheme_code = c.scheme_code) Scheme_Name,
         C.SCHEME_CODE,
         'T-Bill' Scheme_Type,
       c.face_value,
       c.coupon_rate,
       c.yield purchase_yield,
       c.transacted_amount cost,
       k.rate*C.QUANTITY  MARKET_value,
       C.QUANTITY,
       c.scheme_maturity_date,
       C.TRANS_DATE,
       c.price PKRV,
        ( k.rate*C.QUANTITY)-(c.transacted_amount)Unrealized_Gain_Loss,
      DECODE( C.BUY_OR_SELL,'B', 'Purchase','SELL')type
  from fis_contract c, scheme s ,fis_market_rates_contract k
 where c.fund_code = vFUND_CODE
 and c.scheme_code=s.scheme_code
  and s.scheme_code=k.scheme_code
 and k.price_date=c.trans_date
 and k.contract_num=c.contract_num
 and k.fund_code=c.fund_code
 and s.scheme_type_code='TB'
   and c.trans_date between dTransdate and dTransdate
UNION ALL


        select c.fund_code,
       (select s.scheme_name
          from scheme s
         where s.scheme_code = c.scheme_code) Scheme_Name,
         C.SCHEME_CODE,
         'SUKUK' Scheme_Type,
       c.face_value,
       c.coupon_rate,
       c.yield purchase_yield,
       c.transacted_amount cost,
      k.rate*C.QUANTITY  MARKET_value,  
       C.QUANTITY,
       c.scheme_maturity_date,
       C.TRANS_DATE,
       c.price PKRV,
        ( k.rate*C.QUANTITY)-(c.transacted_amount)Unrealized_Gain_Loss,
      DECODE( C.BUY_OR_SELL,'B', 'Purchase','SELL')type
  from fis_contract c, scheme s ,fis_market_rates_contract k
 where c.fund_code = vFUND_CODE
 and c.scheme_code=s.scheme_code
  and s.scheme_code=k.scheme_code
 and k.price_date=c.trans_date
 and k.contract_num=c.contract_num
 and k.fund_code=c.fund_code
 
 and s.scheme_type_code='SU'
   and c.trans_date between dTransdate and dTransdate
   
 UNION ALL
 
 
        select c.fund_code,
       (select s.scheme_name
          from scheme s
         where s.scheme_code = c.scheme_code) Scheme_Name,
         C.SCHEME_CODE,
         'PIB' Scheme_Type,
       c.face_value,
       c.coupon_rate,
       c.yield purchase_yield,
       c.transacted_amount cost,
       k.rate*C.QUANTITY  MARKET_value,
       C.QUANTITY,
       c.scheme_maturity_date,
       C.TRANS_DATE,
       c.price PKRV,
        ( k.rate*C.QUANTITY)-(c.transacted_amount)Unrealized_Gain_Loss,
      DECODE( C.BUY_OR_SELL,'B', 'Purchase','SELL')type
  from fis_contract c, scheme s ,fis_market_rates_contract k
 where c.fund_code = vFUND_CODE
 and c.scheme_code=s.scheme_code
  and s.scheme_code=k.scheme_code
 and k.price_date=c.trans_date
 and k.contract_num=c.contract_num
 and k.fund_code=c.fund_code
 and s.scheme_type_code='PB'
 and c.trans_date between dTransdate and dTransdate
 )

     LOOP
      BEGIN
insert into temp_fixedincomesecurities
  (fund_code,
   scheme_name,
   facevalue,
   coupon,
   purchase_yield,
   cost,
   pkrv,
   marketvalue,
   unrealizedgainloss,
   trndate,
   maturity_date,
    TRANS_TYPE,
    SCHEME_TYPE)
values
  (ALL_TRANS.Fund_Code,
   ALL_TRANS.Scheme_Name,
   ALL_TRANS.Face_Value,
   ALL_TRANS.Coupon_Rate,
   ALL_TRANS.Purchase_Yield,
    ALL_TRANS.COST,
    ALL_TRANS.PKRV,
    ALL_TRANS.Market_Value,
    ALL_TRANS.Unrealized_Gain_Loss,
    ALL_TRANS.TRANS_DATE,
    ALL_TRANS.SCHEME_MATURITY_DATE,
    ALL_TRANS.TYPE,
    ALL_TRANS.SCHEME_TYPE
    );

      exception
        when others then
          dbms_output.put_line('Error: ' || SQLERRM);
      END;
    end loop;

    commit;

  end PopulateFixedIncomeSecurities;
  
   PROCEDURE TrialData(Pdate DATE, vFUND_CODE varchar2) AS
  /*  v_bank_balance number;*/
 

  
 n integer := 0;
 result number;

 financialID number:=1;
 startGLCode varchar2(50):=1;
 endGLCode  varchar2(50):=5050101010101;
 --                      
 openTrial number:=0;
 zeroBal number:=0;
 StartDate date;
 vDescription varchar2(100);
 nPrevMonth number:=0;
 nCurrMonth number:=0;
 nPrevMonthWAPDA number:=0;
 nCurrMonthWAPDA number:=0;


 nPrevMonthTDR number:=0;
 nCurrMonthTDR number:=0;
 nPrevMonthIJ number:=0;
 nCurrMonthIJ number:=0;
 nPrevMonthCSUKUK number:=0;
 nCurrMonthCSUKUK number:=0;

 nPrevMontAsset number:=0;
 nCurrMonthAsset number:=0;

 nCurrMonthDebAmt number:=0;
 nCurrMonthCreAmt number:=0;
 bStatus boolean:= False;

 vFundCode varchar2(10);
 vSymbolIF varchar2(10);
 vSymbolISF varchar2(10);
 vSymbolCF varchar2(10);
 vSymbolIDSF varchar2(10);
 vOthers varchar2(3) := '99';
 A_DATE DATE:='1-AUG-2023';
begin
 delete from temp_trialdata m where m.fund_code=vFUND_CODE and m.findate=A_DATE;
/* 
  WHILE (A_DATE<=Pdate)loop*/
/*for all_funds in ( select f.fund_code,f.fund_short_name from fund f where f.active=1 and f.fund_code=1)*/
 TRIAL_BALANCE_TEST(financialID, A_DATE, Pdate,startGLCode,endGLCode,openTrial,zeroBal,vFUND_CODE);


 FOR all_investment in ( 

      select gl_glmf_description Description, (fpDebit)Debit_Amount, (fpCredit)Credit_Amount, gl_glmf_code gl_code,gl_glmf_description
      gl_head

       from (  select  a.gl_glmf_code, a.gl_glmf_description,   case
         when nvl(a.gl_glmf_fpdr, 0) -
              abs(nvl(a.gl_glmf_fpcr, 0)) < 0 then
          abs(nvl(a.gl_glmf_fpdr, 0) -
              abs(nvl(a.gl_glmf_fpcr, 0)))
         else
          null
       end as fpCredit,
       case
         when nvl(a.gl_glmf_fpdr, 0) -
              abs(nvl(a.gl_glmf_fpcr, 0)) > 0 then
          abs(nvl(a.gl_glmf_fpdr, 0) -
              abs(nvl(a.gl_glmf_fpcr, 0)))
         else
          null
       end as fpDebit from
     tb a where a.gl_glmf_code in (1,
10201,
10201010101,
1020103,
1020104,
1020107,
1020201010201,
1020201010204,
1020301010101,
1020301040101,
1020301050101,
1020302010101,
1020302020101,
1020304010101,
1020304020101,
1020403010102,
1020404020101,
1020501010203,
1020501010301,
1020502010101,
1020506010101,
2,
2010101010201,
2030201010101,
3,
3020301010101,
3020301020102,
3020302010603,
3020302010604,
3020406060101,
3020406060102,
3020406060103,
1020301010101,
1020302010101,
1020302020101,
4,
4010102010101,
4010401010104,
4010501010102,
4020401010235,
4020401010236,
4040301010201,
5,
50101,
5010101010101,
5010102010201,
5010103010101,
5010201010101,
50103,
5010301010101,
5010301020102,
5010301030101,
5010301030102,
502,
5020101010201,
5020201020101,
5020301010101,
5020301010102,
5020301010103
)  ORDER BY A.GL_GLMF_CODE ASC )
     
       /* union all
             
     select 'INVESTMENTS' Description, max(fpDebit)Debit_Amount, max(fpCredit)Credit_Amount,'10201' gl_code,'ASSETS' gl_head

      from (select  a.gl_glmf_code,    case
         when nvl(a.gl_glmf_fpdr, 0) -
              abs(nvl(a.gl_glmf_fpcr, 0)) < 0 then
          abs(nvl(a.gl_glmf_fpdr, 0) -
              abs(nvl(a.gl_glmf_fpcr, 0)))
         else
          null
       end as fpCredit,
       case
         when nvl(a.gl_glmf_fpdr, 0) -
              abs(nvl(a.gl_glmf_fpcr, 0)) > 0 then
          abs(nvl(a.gl_glmf_fpdr, 0) -
              abs(nvl(a.gl_glmf_fpcr, 0)))
         else
          null
       end as fpDebit from
     tb a    where a.gl_glmf_code in
     ('10201')) 
       
         union all
     select 'EQUITY INVESTMENTS' Description, max(fpDebit)Debit_Amount, max( fpCredit)Credit_Amount,'10201010101' gl_code,'ASSETS' gl_head

       from (select  a.gl_glmf_code,    case
         when nvl(a.gl_glmf_fpdr, 0) -
              abs(nvl(a.gl_glmf_fpcr, 0)) < 0 then
          abs(nvl(a.gl_glmf_fpdr, 0) -
              abs(nvl(a.gl_glmf_fpcr, 0)))
         else
          null
       end as fpCredit,
       case
         when nvl(a.gl_glmf_fpdr, 0) -
              abs(nvl(a.gl_glmf_fpcr, 0)) > 0 then
          abs(nvl(a.gl_glmf_fpdr, 0) -
              abs(nvl(a.gl_glmf_fpcr, 0)))
         else
          null
       end as fpDebit from
     tb a    where a.gl_glmf_code in
     ('10201010101'))          
         
         union all 
         
         select 'INVESTMENT IN DEBT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020103' gl_code,'ASSETS' gl_head

       from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020103'))
     
     union all
       select 'INVESTMENT IN GOVERNMENT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020104' gl_code,'ASSETS' gl_head

       from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020104')) 
     
        union all
       select 'INVESTMENT IN PAKISTAN INVESTMENT BOND-PIB' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020107' gl_code,'ASSETS' gl_head

      from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020107')) 
       
      union all
       select 'SCBPL F-7 MARKAZ - TEGF 3302' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020201010201' gl_code,'ASSETS' gl_head

       from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020201010201')) 
     
       union all
       select 'CDC TEGF' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020201010204' gl_code,'ASSETS' gl_head

       from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020201010204'))
     
      
        union all
       select 'RECEIVABLE INVESTMENT IN EQUITY SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020301010101' gl_code,'ASSETS' gl_head

        from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020301010101')) 
     
     
     union all
       select 'INVESTMENT IN DEBT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020301040101' gl_code,'ASSETS' gl_head

        from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020301040101')) 
     
       union all
       select 'INVESTMENT IN GOVERNMENT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020301050101' gl_code,'ASSETS' gl_head

       from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020301050101'))
    
     union all
       select 'AGAINST DEBT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020302010101' gl_code,'ASSETS' gl_head

        from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020302010101')) 
     
        union all
       select 'AGAINST GOVERNMENT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020302020101' gl_code,'ASSETS' gl_head

        from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020302020101'))
      
           union all
       select 'RECEIVABLE AGAINST REDEMPTION OF DEBT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020304010101' gl_code,'ASSETS' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020304010101')) 
     
        union all
       select 'RECEIVABLE AGAINST REDEMPTION OF GOVER SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020304020101' gl_code,'ASSETS' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020304020101'))
      
        union all
       select 'UN-LISTED DEBT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020403010102' gl_code,'ASSETS' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020403010102')) 
     
         union all
       select 'AGAINST GOVERNMENT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020404020101' gl_code,'ASSETS' gl_head

       from (select (a.gl_glmf_updr-b.gl_glmf_updr)gl_glmf_fpdr,(a.gl_glmf_upcr-b.gl_glmf_upcr)gl_glmf_fpcr,a.gl_glmf_code from
     tb a,tb1 b  where a.gl_glmf_code=b.gl_glmf_code and   a.gl_glmf_code in
     ('1020404020101')) 
      
        union all
       select 'WHT ON DIVIDEND INCOME' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020501010203' gl_code,'ASSETS' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020501010203'))
     
          union all
       select 'WITHHOLDING TAX ON PROFIT' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020501010301' gl_code,'ASSETS' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020501010301'))
     
     
        union all
       select 'DIVIDEND RECEIVABLE' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020502010101' gl_code,'ASSETS' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020502010101'))
     
        
        union all
       select 'OTHER RECEIVABLE' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020506010101' gl_code,'ASSETS' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020506010101'))
     
         union all
       select 'EQUITY' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'2' gl_code,'EQUITY' gl_head

        from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('2'))
     
     
         union all
       select 'ISSUED IN CASH' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'2010101010201' gl_code,'EQUITY' gl_head

     from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('2010101010201'))
     
     
              union all
       select 'UNAPPROPRIATED INCOME' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'2030201010101' gl_code,'EQUITY' gl_head

        from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('2030201010101'))
     
          union all
       select 'LIABILITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'3' gl_code,'LIABILITIES' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('3'))
     
               union all
       select 'MANAGEMENT COMP REM PAYABLE' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'3020301010101' gl_code,'LIABILITIES' gl_head
   from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('3020301010101'))
     
         union all
       select 'TRUSTEE REMUNERATION PAYABLE' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'3020301020102' gl_code,'LIABILITIES' gl_head
   from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('3020301020102'))
     
     
      
         union all
       select 'SALE TAX ON MANAGEMENT FEE' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'3020302010603' gl_code,'LIABILITIES' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('3020302010603'))
     
      union all
       select 'SALE TAX ON TRUSTEE FEE' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'3020302010604' gl_code,'LIABILITIES' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('3020302010604'))
     
        union all
       select 'BROKERAGE PAYABLE- HFT' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'3020406060101' gl_code,'LIABILITIES' gl_head

        from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('3020406060101'))
     
            union all
       select 'CVT PAYABLE' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'3020406060102' gl_code,'LIABILITIES' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('3020406060102'))
     
     
          union all
       select 'INVESTMENT IN EQUITY SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020301010101' gl_code,'LIABILITIES' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020301010101'))
     
          union all
       select 'AGAINST DEBT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020302010101' gl_code,'LIABILITIES' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020302010101'))
     
      union all
       select 'AGAINST GOVERNMENT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'1020302020101' gl_code,'LIABILITIES' gl_head

     from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('1020302020101'))
     
          union all
       select 'EXPENSES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'4' gl_code,'EXPENSES' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('4'))
     
          union all
       select 'TRUSTEE REMUNERATION' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'4010102010101' gl_code,'EXPENSES' gl_head

        from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('4010102010101'))
     
        union all
       select 'INVESTMENT IN GOVERNMENT SECURITIES - HTM HFT' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'4010401010104' gl_code,'EXPENSES' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('4010401010104'))
     
           union all
       select 'CDC - SETTLEMENT CHARGES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'4010501010102' gl_code,'EXPENSES' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('4010501010102'))
     
               union all
       select 'SALES TAX ON BROKERAGE' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'4020401010235' gl_code,'EXPENSES' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('4020401010235'))
     
                  union all
       select 'SALE TAX ON TRUSTEE FEE' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'4020401010236' gl_code,'EXPENSES' gl_head
   from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('4020401010236'))
     
                   union all
       select 'BANK CHARGES - SCBPL F-7 MARKAZTEGF' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'4040301010201' gl_code,'EXPENSES' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('4040301010201'))
     
       union all
       select 'INCOME' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5' gl_code,'INCOME' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5'))
     
           union all
       select 'GAIN/ (LOSS) FROM SALE OF INVESTMENTS' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'50101' gl_code,'INCOME' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('50101'))
     
               union all
       select 'EQUITY INVESTMENTS' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5010101010101' gl_code,'INCOME' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5010101010101'))
     
     
               union all
       select 'UN-LISTED DEBT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5010102010201' gl_code,'INCOME' gl_head

    from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5010102010201'))
     
          union all
       select 'HELD FOR TRADING INVESTMENT' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5010103010101' gl_code,'INCOME' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5010103010101'))
     
           union all
       select 'DIVIDEND INCOME ON EQUITY SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5010201010101' gl_code,'INCOME' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5010201010101'))
     
            union all
       select 'UNREALIZED GAIN/ LOSS' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'50103' gl_code,'UNREALIZED GAIN/ LOSS' gl_head

        from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('50103'))
     
            union all
       select 'EQUITY INVESTMENTS' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5010301010101' gl_code,'UNREALIZED GAIN/ LOSS' gl_head
   from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5010301010101'))
     
             union all
       select 'UN-LISTED DEBT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5010301020102' gl_code,'UNREALIZED GAIN/ LOSS' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5010301020102'))
     
            union all
       select 'HELD FOR TRADING INVESTMENT' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5010301030101' gl_code,'UNREALIZED GAIN/ LOSS' gl_head

     from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5010301030101'))
     
               union all
       select 'UNREALIZED GAIN / (LOSS) ON PIB' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5010301030102' gl_code,'UNREALIZED GAIN/ LOSS' gl_head

     from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5010301030102'))
     
                union all
       select 'MARK UP INCOME' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'502' gl_code,'MARK UP INCOME' gl_head

          from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('502'))
     
               union all
       select 'RET SCBPL F-7 MARKAZ - TEGF 3302' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5020101010201' gl_code,'MARK UP INCOME' gl_head

         from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5020101010201'))
                    union all
       select 'UN-LISTED DEBT SECURITIES' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5020201020101' gl_code,'MARK UP INCOME' gl_head

       from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5020201020101'))
     
            union all
       select 'HELD FOR TRADING INVESTMENT' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5020301010101' gl_code,'MARK UP INCOME' gl_head

       from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5020301010101'))
       union all
       select 'AMORTIZATION ON PIB' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5020301010102' gl_code,'MARK UP INCOME' gl_head

      from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5020301010102'))
     
         union all
       select 'INCOME FROM GOVERNMENT SECURITIES-PIB' Description, max(gl_glmf_fpdr)Debit_Amount, max(gl_glmf_fpcr)Credit_Amount,'5020301010103' gl_code,'MARK UP INCOME' gl_head

        from (select  (a.gl_glmf_opdr-a.gl_glmf_opcr) gl_glmf_fpdr ,(a.gl_glmf_updr-a.gl_glmf_upcr)gl_glmf_fpcr, a.gl_glmf_code from
     tb a    where a.gl_glmf_code in
     ('5020301010103'))*/
     
     
     
     
     
           
     
     
     )


     loop

 insert into temp_trialdata(gl_code, description, gl_type, debit_amount, credit_amount, findate, fund_code)
values
  (all_investment.gl_code, all_investment.description, all_investment.gl_head, all_investment.debit_amount, all_investment.credit_amount,A_DATE, vFUND_CODE);
     end loop;
       
         
     



commit;



result:=1;
/*return result;*/
 end TrialData;
end Portfolio_Dashboard1;
/
