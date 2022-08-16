-- ID пользователя
-- Страна
-- Дата и время регистрации
-- Дата и время первого депозита
-- Дата и время первой сделки (если есть)
-- Сумма первого депозита
-- Прибыль/убыток первой сделки
-- Общий депозит за первые 30 дней с момента регистрации
-- Суммарный вывод за первые 30 дней после регистрации
-- Общая прибыль/убыток за первые 30 дней после регистрации
-- ОБЩАЯ прибыль/убыток за время жизни пользователя




WITH first_trade as (
	SELECT user_id,
		profit_usd,
		open_time,
		close_time,
		ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY open_time, close_time) as row_n  
	FROM orders
	),
	
first_deposit as (
	SELECT user_id,
		operation_time,
		ROUND(SUM(operation_amount_usd)::numeric, 2) as sum_first_dep,
		RANK() OVER(PARTITION BY user_id ORDER BY operation_time) as rnk
	FROM balance
	WHERE operation_type = 'deposit' 
	GROUP BY user_id, operation_time
	),

first_30day_profit as (
	SELECT o.user_id,
		ROUND(SUM(profit_usd)::numeric, 2) as profit_30day
	FROM orders o 
		JOIN users u ON u.user_id = o.user_id 
			AND u.registration_time + interval '30' day >= o.close_time
	GROUP BY o.user_id	
		),
		
first_30day_balance as (
	SELECT b.user_id,
		ROUND(SUM(CASE WHEN operation_type = 'deposit' 
			THEN operation_amount_usd ELSE null END)::numeric, 2) as deposit_30day,
		ROUND(SUM(CASE WHEN operation_type = 'withdrawal'
		   	THEN operation_amount_usd ELSE null END)::numeric, 2) as withdrawal_30day
	FROM balance b 
		JOIN users u ON u.user_id = b.user_id 
			AND u.registration_time + interval '30' day >= b.operation_time
	GROUP BY b.user_id	
		),
		
total_profit as (
	SELECT user_id,
		ROUND(SUM(profit_usd)::numeric, 2) as total_profit
	FROM orders
	GROUP BY user_id
		)

SELECT u.user_id,
	u.country_code as country,
	u.registration_time,
	first_deposit.operation_time as date_first_deposit,
	first_trade.open_time as date_first_trade,
	first_deposit.sum_first_dep as first_deposit,
	first_trade.profit_usd as profit_first_trade,
	first_30day_balance.deposit_30day as total_deposit_30day,
	first_30day_balance.withdrawal_30day as total_withdrawal_30day,
	first_30day_profit.profit_30day as total_profit_30day,
	total_profit.total_profit as total_profit
FROM
	(SELECT users.*,
		 ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY registration_time) as user_reg_num 
	 FROM users) u 
	 
	JOIN first_trade ON first_trade.user_id = u.user_id and row_n = 1
	JOIN first_deposit ON first_deposit.user_id = u.user_id and rnk = 1
	JOIN first_30day_balance ON first_30day_balance.user_id = u.user_id
	JOIN first_30day_profit ON first_30day_profit.user_id = u.user_id
	JOIN total_profit ON total_profit.user_id = u.user_id

WHERE u.user_reg_num = 1

