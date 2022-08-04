-- Общее количество пользователей из этой страны
-- Количество пользователей, сделавших хотя бы один депозит
-- Средняя сумма депозита по стране
-- Средняя сумма вывода по стране



WITH tbl1 AS (
	SELECT user_id,
		CASE WHEN operation_type = 'deposit'
			THEN operation_amount_usd ELSE null END AS deposit,
		CASE WHEN operation_type = 'withdrawal' 
			THEN operation_amount_usd ELSE null END AS withdrawal
	FROM balance)
	
SELECT us_row.country_code,
	COUNT(DISTINCT us_row.user_id) as cnt_user_from_country,
	COUNT(DISTINCT tbl1.user_id) as cnt_user_deposit,
	round(AVG(tbl1.deposit)::numeric, 2) as avg_deposit,
	round(AVG(tbl1.withdrawal)::numeric, 2) as avg_withdrawal
FROM (
	SELECT *,
		row_number() over(partition by user_id order by registration_time) as user_reg_num
	FROM users) us_row
LEFT JOIN tbl1 ON tbl1.user_id = us_row.user_id
WHERE user_reg_num = 1
GROUP BY us_row.country_code
ORDER BY 2 desc;