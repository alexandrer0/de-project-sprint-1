insert into
	analysis.dm_rfm_segments
(user_id,
	recency,
	frequency,
	monetary_value)
select
	rr.user_id,
	rr.recency,
	rf.frequency,
	rm.monetary_value
from
	analysis.tmp_rfm_recency rr
join analysis.tmp_rfm_frequency rf on
	rr.user_id = rf.user_id
join analysis.tmp_rfm_monetary_value rm on
	rr.user_id = rm.user_id
;