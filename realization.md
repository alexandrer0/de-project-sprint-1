# Витрина RFM

## 1.1. Выясните требования к целевой витрине.

1. Витрина должна быть создана в схеме analysis, с наименованием dm_rfm_segments
2. Витрина содержит 4 поля:
    user_id
    recency (число от 1 до 5)
    frequency (число от 1 до 5)
    monetary_value (число от 1 до 5)
3. Витрина содержит данные с 01.01.2022 по настоящее время
4. Витрину посчитать один раз, обновление данных не требуется
5. Успепшно выполненный заказ - заказ со статусом Closed

## 1.2. Изучите структуру исходных данных.

Исходные данные находятся в схеме production.
users - данные о пользователях
orders - данные о заказах
products - данные о продуктах
orderitems - детализация заказов по продуктам
orderstatuses - справочник статусов
orderstatuslog - логи изменения статусов заказов
Для расчета витрины необходимы источники из схемы production:
    users (id),
    orders (order_id, user_id, order_ts, cost)

## 1.3. Проанализируйте качество данных

Для проверки качества выполнено следующее:
1. Обзорный анализ данных
2. Анализ ER-диаграммы
3. Анализ DDL по каждой таблице

Качество данных в схеме production обеспечивается с помощью инструментов:

| Таблицы        | Объект                                                          | Инструмент            | Для чего используется                                                                                 |
|----------------|-----------------------------------------------------------------|-----------------------|-------------------------------------------------------------------------------------------------------|
| Products       | id int4 NOT NULL PRIMARY KEY                                    | Первичный ключ        | Обеспечивает уникальность записей о продуктах                                                         |
| Products       | CHECK (price >= 0)                                              | Проверка значения     | Проверка гарантирует, что цена продукта не отрицательна                                               |
| Users          | id int4 NOT NULL PRIMARY KEY                                    | Первичный ключ        | Обеспечивает уникальность записей о пользователях                                                     |
| Orders         | order_id int4 NOT NULL PRIMARY KEY                              | Первичный ключ        | Обеспечивает уникальность записей о заказах                                                           |
| Orders         | CHECK (cost = (payment + bonus_payment))                        | Проверка значения     | Проверка гарантирует, что стоимость заказа равна сумме платежа и бонуса                               |
| Orderitems     | id int4 NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY       | Первичный ключ        | Обеспечивает уникальность записей в таблице по синтетическому ключу                                   |
| Orderitems     | CHECK ((discount >= 0) AND (discount <= price))                 | Проверка значения     | Проверка гарантирует, что скидка не больше чем цена                                                   |
| Orderitems     | CHECK (price >= 0)                                              | Проверка значения     | Проверка гарантирует, что цена продукта в заказе не отрицательна                                      |
| Orderitems     | CHECK (quantity > 0)                                            | Проверка значения     | Проверка гарантирует, что количество продукта в заказе не отрицательно                                |
| Orderitems     | UNIQUE (order_id, product_id)                                   | Проверка уникальности | Обеспечивает уникальность записей в таблице по паре Заказ - Продукт                                   |
| Orderitems     | FOREIGN KEY (order_id) REFERENCES production.orders(order_id)   | Внешний ключ          | Обеспечивает целостность данных: в таблице могут быть только те заказы, которые есть в Orders         |
| Orderitems     | FOREIGN KEY (product_id) REFERENCES production.products(id)     | Внешний ключ          | Обеспечивает целостность данных: в таблице могут быть только те продукты, которые есть в Products     |
| Orderstatuslog | id int4 NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY       | Первичный ключ        | Обеспечивает уникальность записей в таблице по синтетическому ключу                                   |
| Orderstatuslog | UNIQUE (order_id, status_id)                                    | Проверка уникальности | Обеспечивает уникальность записей в таблице по паре Заказ - Статус                                    |
| Orderstatuslog | FOREIGN KEY (order_id) REFERENCES production.orders(order_id)   | Внешний ключ          | Обеспечивает целостность данных: в таблице могут быть только те заказы, которые есть в Orders         |
| Orderstatuslog | FOREIGN KEY (status_id) REFERENCES production.orderstatuses(id) | Внешний ключ          | Обеспечивает целостность данных: в таблице могут быть только те статусы, которые есть в Orderstatuses |
| Orderstatuses  | id int4 NOT NULL PRIMARY KEY                                    | Первичный ключ        | Обеспечивает уникальность записей о статусах заказов                                                  |

Качество данных высокое, для этого используется много инструментов, вопросов по качеству нет.
Единственное, я бы добавил ограничение на user_id в таблице orders - внешний ключ к таблице users.

## 1.4. Подготовьте витрину данных

### 1.4.1. Сделайте VIEW для таблиц из базы production.**

```
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
```

### 1.4.2. Напишите DDL-запрос для создания витрины.**

```
CREATE TABLE analysis.dm_rfm_segments (
	user_id INT NOT NULL PRIMARY KEY,
	recency INT NOT NULL CHECK(recency >= 1 AND recency <= 5),
	frequency INT NOT NULL CHECK(frequency >= 1 AND frequency <= 5),
	monetary_value INT NOT NULL CHECK(monetary_value >= 1 AND monetary_value <= 5) 
);
```

### 1.4.3. Напишите SQL запрос для заполнения витрины

```
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

--Первые 10 строк
user_id	recency	frequency monetary_value
0	1	3	4
1	4	3	3
2	2	3	5
3	2	3	3
4	4	3	3
5	5	5	5
6	1	3	5
7	4	2	2
8	1	2	3
9	1	3	2
```

## 2. Доработка представлений

```
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
```