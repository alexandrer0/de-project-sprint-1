create or replace
view analysis.orders as
with osl as
(
select
	distinct on
	(order_id) order_id,
	status_id as status
from
	production.orderstatuslog
order by
	order_id,
	dttm desc,
	status_id desc)
select
	o.order_id,
	o.order_ts,
	o.user_id,
	o.bonus_payment,
	o.payment,
	o."cost",
	o.bonus_grant,
	osl.status
from
	production.orders as o
join osl on
	o.order_id = osl.order_id
;