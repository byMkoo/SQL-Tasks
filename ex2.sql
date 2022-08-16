-- ID этого пользователя
-- Его код страны
-- Его прибыль
-- Общая сумма сделок
-- Количество прибыльных сделок
-- Самый популярный торговый инструмент (символ). Позиция с наибольшим количеством открытых ордеров для этого пользователя
-- Символ с самым высоким уровнем прибыли
-- Символ с самым высоким уровнем проигрыша





WITH tbl1 as (
	SELECT user_id
	FROM (
	SELECT user_id,
		 SUM(profit_usd) as total_profit,
		 RANK() OVER(ORDER BY SUM(profit_usd) desc) as rank
	FROM orders
		GROUP BY user_id
		) as user_sum_profit	
	WHERE rank=1
),
	
tbl2 as (
	SELECT o.user_id,
		 symbol,
	 	COUNT(o.profit_usd) as cnt_deals,
	 	COUNT(CASE WHEN profit_usd > 0 
			THEN profit_usd ELSE null END) as cnt_profit,
	 	SUM(profit_usd) as sum_profit,
	 	FIRST_VALUE(symbol) OVER(PARTITION BY o.user_id ORDER BY SUM(profit_usd) asc) as symbol_loss,
	 	FIRST_VALUE(symbol) OVER(PARTITION BY o.user_id ORDER BY SUM(profit_usd) desc) as symbol_profit,
	 	FIRST_VALUE(symbol) OVER(PARTITION BY o.user_id ORDER BY COUNT(profit_usd) desc) as symbol_populare
	
	FROM orders o
		JOIN tbl1 ON tbl1.user_id = o.user_id
	WHERE o.user_id = (SELECT user_id FROM tbl1)
	
	GROUP BY o.user_id, symbol
)
	
SELECT tbl2.user_id,
	user_info.country,
	ROUND(SUM(sum_profit)::numeric, 2) as sum_profit, 
	SUM(cnt_deals) as cnt_deals, 
	SUM(cnt_profit) as cnt_profit,
	symbol_populare, 
	symbol_profit,
	symbol_loss
FROM tbl2 
	JOIN (SELECT country_code as country,
            user_id 
      	 FROM users 
      	 WHERE user_id = (SELECT user_id FROM tbl1)
		) as user_info
	ON user_info.user_id = tbl2.user_id

GROUP BY tbl2.user_id,
    user_info.country, 
    symbol_populare,
	symbol_profit,
	symbol_loss 