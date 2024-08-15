
--order per day
SELECT
	OS.ORDER_DATE,
	SUM(OD.AMOUNT * OD.QUANTITY)
FROM
	ORDER_SUMMARY OS
	INNER JOIN ORDER_DETAILS OD ON OS.ORDER_ID = OD.ORDER_ID
GROUP BY
	OS.ORDER_DATE
ORDER BY
	OS.ORDER_DATE;



--find out the total sum of quantities sold under each order id 
SELECT
	A.ORDER_ID,
	SUM(A.QUANTITY)
FROM
	ORDER_DETAILS A
	INNER JOIN ORDER_SUMMARY B ON A.ORDER_ID = B.ORDER_ID
GROUP BY
	A.ORDER_ID
ORDER BY
	ORDER_ID;



--highest and lowest quanity sold 
(
	SELECT
		COUNT(QUANTITY),
		CATEGORY
	FROM
		ORDER_DETAILS
	GROUP BY
		CATEGORY
	ORDER BY
		COUNT(QUANTITY) DESC
	LIMIT
		1
)
UNION ALL
(
	SELECT
		COUNT(QUANTITY),
		CATEGORY
	FROM
		ORDER_DETAILS
	GROUP BY
		CATEGORY
	ORDER BY
		COUNT(QUANTITY)
	LIMIT
		1
);



--difference between monthly target and monthly sales by each category
SELECT
	ST.ORDER_DATE,
	SQ.MONTHS,
	ST.CATEGORY,
	SQ.MONTHLY_TOTAL_SALES,
	ST.TARGET,
	ST.TARGET - SQ.MONTHLY_TOTAL_SALES AS DIFFERENCE
FROM
	SALES_TARGET ST
	LEFT JOIN (
		SELECT
			A.CATEGORY,
			SUM(A.AMOUNT * A.QUANTITY) AS MONTHLY_TOTAL_SALES,
			EXTRACT(
				MONTH
				FROM
					B.ORDER_DATE
			) AS MONTHS
		FROM
			ORDER_DETAILS A
			INNER JOIN ORDER_SUMMARY B ON A.ORDER_ID = B.ORDER_ID
		WHERE
			EXTRACT(
				MONTH
				FROM
					B.ORDER_DATE
			) IN (
				SELECT
					EXTRACT(
						MONTH
						FROM
							ST.ORDER_DATE
					)
				FROM
					SALES_TARGET ST
			)
		GROUP BY
			EXTRACT(
				YEAR
				FROM
					B.ORDER_DATE
			),
			MONTHS,
			A.CATEGORY
	) SQ ON EXTRACT(
		MONTH
		FROM
			ST.ORDER_DATE
	) = SQ.MONTHS
	AND ST.CATEGORY = SQ.CATEGORY
ORDER BY
	EXTRACT(
		YEAR
		FROM
			ST.ORDER_DATE
	),
	SQ.MONTHS,
	ST.CATEGORY;





--Identify orders where the target wasnt met 
SELECT
	SBQ.MONTHS,
	ST.TARGET,
	SBQ.MONTHLY_SALES,
	SBQ.CATEGORY
FROM
	SALES_TARGET ST
	LEFT JOIN (
		SELECT
			SUM(A.AMOUNT * A.QUANTITY) AS MONTHLY_SALES,
			EXTRACT(
				MONTH
				FROM
					B.ORDER_DATE
			) AS MONTHS,
			A.CATEGORY
		FROM
			ORDER_SUMMARY B
			INNER JOIN ORDER_DETAILS A ON A.ORDER_ID = B.ORDER_ID
		WHERE
			EXTRACT(
				MONTH
				FROM
					ORDER_DATE
			) IN (
				SELECT
					EXTRACT(
						MONTH
						FROM
							ST.ORDER_DATE
					)
				FROM
					SALES_TARGET ST
			)
		GROUP BY
			MONTHS,
			A.CATEGORY
	) AS SBQ ON EXTRACT(
		MONTH
		FROM
			ST.ORDER_DATE
	) = SBQ.MONTHS
	AND ST.CATEGORY = SBQ.CATEGORY
WHERE
	ST.TARGET > SBQ.MONTHLY_SALES
ORDER BY
	SBQ.MONTHS;




--calculate the percentage of the highest monthly sales compared to the total yearly sales
SELECT
	(BC.TOTAL_SALES / AB.TOTAL_SALES_YEARLY) * 100
FROM
	(
		SELECT
			SUM(AMOUNT * QUANTITY) AS TOTAL_SALES_YEARLY
		FROM
			ORDER_DETAILS
	) AB
	CROSS JOIN (
		SELECT
			SUM(A.AMOUNT * A.QUANTITY) AS TOTAL_SALES,
			EXTRACT(
				MONTH
				FROM
					B.ORDER_DATE
			) AS MONTHS
		FROM
			ORDER_DETAILS A
			INNER JOIN ORDER_SUMMARY B ON A.ORDER_ID = B.ORDER_ID
		GROUP BY
			MONTHS
		ORDER BY
			TOTAL_SALES DESC
		LIMIT
			1
	) BC;




--List the top 3 customers with the highest total purchase amount for each month.
SELECT
	CUSTOMER_NAME,
	TOTAL_SALES,
	YEARS,
	MONTHS,
	SALES_RANK
FROM
	(
		SELECT
			OS.CUSTOMER_NAME,
			SUM(OD.AMOUNT * OD.QUANTITY) AS TOTAL_SALES,
			EXTRACT(
				YEAR
				FROM
					OS.ORDER_DATE
			) AS YEARS,
			EXTRACT(
				MONTH
				FROM
					OS.ORDER_DATE
			) AS MONTHS,
			RANK() OVER (
				PARTITION BY
					EXTRACT(
						MONTH
						FROM
							OS.ORDER_DATE
					)
				ORDER BY
					SUM(OD.AMOUNT * OD.QUANTITY) DESC
			) AS SALES_RANK
		FROM
			ORDER_SUMMARY OS
			INNER JOIN ORDER_DETAILS OD ON OS.ORDER_ID = OD.ORDER_ID
		GROUP BY
			YEARS,
			MONTHS,
			OS.CUSTOMER_NAME,
			OS.STATE,
			OS.CITY
	)
WHERE
	SALES_RANK <= 3
ORDER BY
	YEARS,
	MONTHS,
	SALES_RANK;




--lowest sale city 
SELECT
	CITY
FROM
	(
		SELECT
			B.CITY,
			SUM(A.AMOUNT * A.QUANTITY) AS MONTHLY_SALES
		FROM
			ORDER_DETAILS A
			INNER JOIN ORDER_SUMMARY B ON A.ORDER_ID = B.ORDER_ID
		GROUP BY
			B.STATE,
			B.CITY
		ORDER BY
			MONTHLY_SALES
	)
LIMIT
	1;




--how many customers purchased more than once 
SELECT
	A.CUSTOMER_NAME,
	COUNT(DISTINCT (B.ORDER_ID)) AS FRQ
FROM
	ORDER_DETAILS B
	INNER JOIN ORDER_SUMMARY A ON A.ORDER_ID = B.ORDER_ID
GROUP BY
	A.CUSTOMER_NAME,
	A.STATE,
	A.CITY
HAVING
	COUNT(DISTINCT (B.ORDER_ID)) > 1
ORDER BY
	FRQ DESC;




--top 3 customers based on their purchases 
SELECT
	OS.CUSTOMER_NAME,
	SUM(OD.AMOUNT * OD.QUANTITY) AS TOTAL_ORDER
FROM
	ORDER_SUMMARY OS
	INNER JOIN ORDER_DETAILS OD ON OS.ORDER_ID = OD.ORDER_ID
GROUP BY
	OS.CUSTOMER_NAME,
	OS.STATE,
	OS.CITY
ORDER BY
	TOTAL_ORDER DESC
LIMIT
	3;




--top 3 highest sales city
SELECT
	CITY
FROM
	(
		SELECT
			B.CITY,
			SUM(A.AMOUNT * A.QUANTITY) AS MONTHLY_SALES
		FROM
			ORDER_DETAILS A
			INNER JOIN ORDER_SUMMARY B ON A.ORDER_ID = B.ORDER_ID
		GROUP BY
			B.STATE,
			B.CITY
		ORDER BY
			MONTHLY_SALES DESC
	)
LIMIT
	3;




--Cities where these categories are performing well
SELECT
	CATEGORY,
	CITY,
	SALES
FROM
	(
		SELECT
			A.CATEGORY,
			B.CITY,
			SUM(A.AMOUNT * A.QUANTITY) AS SALES
		FROM
			ORDER_DETAILS A
			INNER JOIN ORDER_SUMMARY B ON A.ORDER_ID = B.ORDER_ID
		GROUP BY
			A.CATEGORY,
			B.STATE,
			B.CITY
		ORDER BY
			A.CATEGORY,
			SALES DESC
	);




--monthly sales by each category
SELECT
	A.CATEGORY,
	SUM(A.AMOUNT * A.QUANTITY) AS TS,
	EXTRACT(
		YEAR
		FROM
			B.ORDER_DATE
	) AS YEARS,
	EXTRACT(
		MONTH
		FROM
			B.ORDER_DATE
	) AS MONTHS
FROM
	ORDER_DETAILS A
	INNER JOIN ORDER_SUMMARY B ON A.ORDER_ID = B.ORDER_ID
GROUP BY
	ROLLUP (YEARS, MONTHS, A.CATEGORY)
ORDER BY
	YEARS,
	MONTHS,
	A.CATEGORY;



--which category has generated the highest revenue 
SELECT
	SUM(AMOUNT * QUANTITY) AS TOTAL_SALES,
	CATEGORY
FROM
	ORDER_DETAILS
GROUP BY
	CATEGORY
ORDER BY
	TOTAL_SALES DESC
LIMIT
	1;



--which category has highest sales in each month
SELECT
	CATEGORY,
	TOTAL_SALES,
	YEARS,
	MONTHS
FROM
	(
		SELECT
			A.CATEGORY,
			SUM(A.AMOUNT * A.QUANTITY) TOTAL_SALES,
			EXTRACT(
				YEAR
				FROM
					B.ORDER_DATE
			) AS YEARS,
			EXTRACT(
				MONTH
				FROM
					B.ORDER_DATE
			) AS MONTHS,
			RANK() OVER (
				PARTITION BY
					EXTRACT(
						MONTH
						FROM
							B.ORDER_DATE
					)
				ORDER BY
					SUM(A.AMOUNT * A.QUANTITY) DESC
			) AS RANKS
		FROM
			ORDER_DETAILS A
			INNER JOIN ORDER_SUMMARY B ON A.ORDER_ID = B.ORDER_ID
		GROUP BY
			(YEARS, MONTHS, A.CATEGORY)
	)
WHERE
	RANKS = 1
ORDER BY
	YEARS,
	MONTHS;



--Identify the month with the highest sales for each category in the year
SELECT
	CATEGORY,
	MONTHS
FROM
	(
		SELECT
			EXTRACT(
				MONTH
				FROM
					B.ORDER_DATE
			) AS MONTHS,
			A.CATEGORY,
			SUM(A.AMOUNT * A.QUANTITY) AS TOTAL_SALES_PM,
			RANK() OVER (
				PARTITION BY
					CATEGORY
				ORDER BY
					SUM(A.AMOUNT * A.QUANTITY) DESC
			) AS RANKS
		FROM
			ORDER_DETAILS A
			INNER JOIN ORDER_SUMMARY B ON A.ORDER_ID = B.ORDER_ID
		GROUP BY
			A.CATEGORY,
			MONTHS
	)
WHERE
	RANKS = 1;



--Determine the category with the highest growth in sales compared to the previous month.
SELECT
	CATEGORY,
	MAX(NEXT_MS - TS) AS GROWTH
FROM
	(
		SELECT
			CATEGORY,
			TS,
			LEAD(TS) OVER (
				PARTITION BY
					CATEGORY
				ORDER BY
					CATEGORY
			) AS NEXT_MS,
			MONTHS
		FROM
			(
				SELECT
					A.CATEGORY,
					SUM(A.AMOUNT * A.QUANTITY) AS TS,
					EXTRACT(
						YEAR
						FROM
							B.ORDER_DATE
					) AS YEARS,
					EXTRACT(
						MONTH
						FROM
							B.ORDER_DATE
					) AS MONTHS
				FROM
					ORDER_DETAILS A
					INNER JOIN ORDER_SUMMARY B ON A.ORDER_ID = B.ORDER_ID
				GROUP BY
					YEARS,
					MONTHS,
					A.CATEGORY
				ORDER BY
					A.CATEGORY,
					YEARS,
					MONTHS
			)
	)
GROUP BY
	CATEGORY
ORDER BY
	GROWTH DESC
LIMIT
	1;