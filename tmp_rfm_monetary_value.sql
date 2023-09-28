insert into
	analysis.tmp_rfm_monetary_value
(user_id, monetary_value)
with so as (
	select
		u.id,
		sum(coalesce(cost, 0)) order_sum
	from
		analysis.users u
	left join analysis.orders o on
		u.id = o.user_id
		and o.status = 4
	group by
		1
)
select
	id,
	ntile(5) over (
order by
	order_sum) monetary_value
from
	so
;