insert into
	analysis.tmp_rfm_frequency
(user_id, frequency)
with co as (
	select
		u.id,
		count(order_id) order_count
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
	order_count) frequency
from
	co
;