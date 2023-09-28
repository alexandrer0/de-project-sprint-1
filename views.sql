create or replace
view analysis.users as
select
	id,
	"name",
	login
from
	production.users;

create or replace
view analysis.products as
select
	id,
	"name",
	price
from
	production.products;

create or replace
view analysis.orders as
select
	order_id,
	order_ts,
	user_id,
	bonus_payment,
	payment,
	"cost",
	bonus_grant,
	status
from
	production.orders;

create or replace
view analysis.orderstatuses as
select
	id,
	"key"
from
	production.orderstatuses;

create or replace
view analysis.orderitems as
select
	id,
	product_id,
	order_id,
	"name",
	price,
	discount,
	quantity
from
	production.orderitems;