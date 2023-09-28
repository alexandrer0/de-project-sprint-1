insert into
	analysis.tmp_rfm_recency
(user_id, recency)
with lo as (
	select
		u.id,
		max(order_ts) last_order_dt
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
	last_order_dt nulls first) recency
from
	lo
;