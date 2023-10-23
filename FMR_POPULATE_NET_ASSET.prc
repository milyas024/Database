create or replace procedure FMR_POPULATE_NET_ASSET(p_sdate date,p_edate date,P_FUND FUND.FUND_CODE%TYPE) is
a_date date;
v_net_asset number(16,4);

begin

a_date:=p_sdate;

  delete fmr_net_asset p where p.price_date between p_sdate and p_edate and p.fund_code=P_FUND;
  commit;

while (a_date<=p_edate)loop

v_net_asset:=fund_net_assets_as_on_date(P_FUND,a_date );


insert into fmr_net_asset
               (fund_code, price_date, net_assets, description)
             values
               (P_FUND,a_date,v_net_asset,'');
a_date:=a_date+1;
end loop;


end;
/
