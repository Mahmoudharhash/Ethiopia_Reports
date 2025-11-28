--------------------------------------------------------------------
-- Converted Sizes into grams
-------------------------------------------------------------------- 
WITH Sizes_Cleaned as 
(
	SELECT
			CASE when [category_code] =3 then 'Total Toilet soap' END as Category
			,[sku_code]
			,[sku_description]
			,[manufacturer_code]
			,[manufacturer_description]
			,[brand_code]
			,[brand_description]
			,[variant_code]
			,[variant_description]
			,[flavour_code]
			,[flavour_description]
			,[packtype_code]
			,[packtype_description]
			,[size_code]
			,[size_description],
			CASE
				--------------------------------------------------------------------
				-- CASE 1 : Other
				--------------------------------------------------------------------
				WHEN size_description LIKE '%other%' THEN 'Other'

				--------------------------------------------------------------------
				-- CASE 2 : (4*80g) 320g --- اشتغل على اللي برا القوسين
				--------------------------------------------------------------------
				WHEN size_description LIKE '%(%*%)%' 
					 AND size_description LIKE '%) %'
				THEN 
					TRIM(
						REPLACE(
							REPLACE(
								REPLACE(
									RIGHT(size_description, LEN(size_description) - CHARINDEX(')', size_description)),
								'g',''),
							'ml',''),
						'lt','')
					)

				--------------------------------------------------------------------
				-- CASE 3 : 4*100g (400g) --- اشتغل على اللي جوا القوسين
				--------------------------------------------------------------------
				WHEN size_description LIKE '%*%(%g%)%' 
				THEN 
					TRIM(
						REPLACE(
							REPLACE(
								REPLACE(
									SUBSTRING(
										size_description,
										CHARINDEX('(', size_description) + 1,
										CHARINDEX(')', size_description) - CHARINDEX('(', size_description) - 1
									),
								'g',''),
							'ml',''),
						'lt','')
					)

				--------------------------------------------------------------------
				-- CASE 4 : 7oz (200g) / 8oz (237ml) / 33.8oz (1lt)
				-- ناخد اللي جوا القوسين
				--------------------------------------------------------------------
				WHEN size_description LIKE '%(%g)%' OR 
					 size_description LIKE '%(%ml)%' OR
					 size_description LIKE '%(%lt)%'
				THEN
					CASE
						WHEN size_description LIKE '%g)%' THEN
							TRIM(REPLACE(
								SUBSTRING(size_description,
									CHARINDEX('(', size_description) + 1,
									CHARINDEX(')', size_description) - CHARINDEX('(', size_description) - 1
								),
							'g',''))

						WHEN size_description LIKE '%ml)%' THEN
							TRIM(REPLACE(
								SUBSTRING(size_description,
									CHARINDEX('(', size_description) + 1,
									CHARINDEX(')', size_description) - CHARINDEX('(', size_description) - 1
								),
							'ml',''))

						WHEN size_description LIKE '%lt)%' THEN
							TRIM(REPLACE(
								SUBSTRING(size_description,
									CHARINDEX('(', size_description) + 1,
									CHARINDEX(')', size_description) - CHARINDEX('(', size_description) - 1
								),
							'lt','')) + '000'
					END

				--------------------------------------------------------------------
				-- CASE 5 : 3.17 (90g) --- ناخد اللي بين القوسين
				--------------------------------------------------------------------
				WHEN size_description LIKE '% (%g)%'
				THEN
					TRIM(
						REPLACE(
							SUBSTRING(
								size_description,
								CHARINDEX('(', size_description) + 1,
								CHARINDEX(')', size_description) - CHARINDEX('(', size_description) - 1
							),
						'g','')
					)

				--------------------------------------------------------------------
				-- CASE 6 : 5lt / 750ml
				--------------------------------------------------------------------
				WHEN size_description LIKE '%ml' AND size_description NOT LIKE '%(%'
				THEN TRIM(REPLACE(size_description,'ml',''))

				WHEN size_description LIKE '%lt' AND size_description NOT LIKE '%(%'
				THEN TRIM(REPLACE(size_description,'lt','')) + '000'

				--------------------------------------------------------------------
				-- CASE 7 : 90g
				--------------------------------------------------------------------
				WHEN size_description LIKE '%g' THEN 
					TRIM(REPLACE(size_description,'g',''))

				--------------------------------------------------------------------
				ELSE size_description
			END AS grams_cleaned
			,[format_code]
			,[format_description]
			,[birthdate]
	FROM [ethiopia].[dbo].[dim_sku]
	WHERE category_code = 3 
)
--------------------------------------------------------------------
-- Classified all Sizes into Groups
--------------------------------------------------------------------
,Sizes_group as
(
	SELECT   Category
			,[sku_code]
			,[sku_description]
			,[manufacturer_code]
			,[manufacturer_description]
			,[brand_code]
			,[brand_description]
			,[variant_code]
			,[variant_description]
			,[flavour_code]
			,[flavour_description]
			,[packtype_code]
			,[packtype_description]
			,[size_code]
			,[size_description]
			,grams_cleaned,
		CASE 
			WHEN TRY_CAST(grams_cleaned AS FLOAT) IS NOT NULL THEN
  ----------------------------------------------------------------------------------------------------------------------------------------
--  Can the value in grams_cleaned be converted to a number? If yes → go to the classification If no → go to the value 'Other'
  ----------------------------------------------------------------------------------------------------------------------------------------
				CASE
					WHEN TRY_CAST(grams_cleaned AS FLOAT) <= 50 THEN '<=50 gm'
					WHEN TRY_CAST(grams_cleaned AS FLOAT) BETWEEN 51 AND 100 THEN '51 - 100 gm'
					WHEN TRY_CAST(grams_cleaned AS FLOAT) BETWEEN 101 AND 150 THEN '101 - 150 gm'
					WHEN TRY_CAST(grams_cleaned AS FLOAT) > 150 THEN '+150 gm'
				END
			ELSE 'Other'
		END AS Size_Group
		,[format_code]
		,[format_description]
		,[birthdate]
	FROM Sizes_Cleaned
)

--------------------------------------------------------------------
-- GET Final Report
--------------------------------------------------------------------
SELECT SOAPC
FROM 
(
	select 
		REPLICATE(' ',0) + Category as SOAPC,
			Category,
			Null as format_description ,
			Null as Brand_description ,
			Null as Size_Group,
			Null as sku_description,
			0 as Lvl
	from Sizes_group
	GROUP BY Category

	UNION ALL

	select 
		REPLICATE(' ',1) + format_description as SOAPC,
			Category,
			format_description as format_description ,
			Null as Brand_description ,
			Null as Size_Group,
			Null as sku_description,
			1 as Lvl
	from Sizes_group
	GROUP BY Category,format_description

	UNION ALL

	select 
		REPLICATE(' ',3) + Brand_description as SOAPC,
			Category,
			format_description as format_description ,
			Brand_description as Brand_description ,
			Null as Size_Group,
			Null as sku_description,
			2 as Lvl
	from Sizes_group
	GROUP BY Category,format_description,Brand_description

	UNION ALL

	select 
		REPLICATE(' ',5) + Size_Group as SOAPC,
			Category,
			format_description as format_description ,
			Brand_description as Brand_description ,
			Size_Group as Size_Group,
			Null as sku_description,
			3 as Lvl
	from Sizes_group
	GROUP BY Category,format_description,Brand_description,Size_Group

	UNION ALL

	select 
		REPLICATE(' ',7) + sku_description as SOAPC,
			Category,
			format_description as format_description ,
			Brand_description as Brand_description ,
			Size_Group as Size_Group,
			sku_description as sku_description,
			3 as Lvl
	from Sizes_group
	GROUP BY Category,format_description,Brand_description,Size_Group,sku_description
) as t

ORDER BY 
	Category,
	format_description,
	Brand_description,
	Size_Group,
	sku_description
