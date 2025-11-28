--------------------------------------------------------------------
1 -- Dictionary after execluding brand 5,6
--------------------------------------------------------------------
WITH Dictionary AS 
(
	SELECT
		  CASE when [category_code] =26 then 'Total Buillon and Savoury' END as Category
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
		  ,[size_nominal_weight]
		  ,[format_code]
		  ,[format_description]
		  ,[birthdate]
	FROM [ethiopia].[dbo].[dim_sku]
	WHERE category_code = 26  
		and brand_code not in (4,5)
)
--------------------------------------------------------------------
2 -- Generate the required report 
--------------------------------------------------------------------
,AllLevels as
(
	SELECT 
		Replicate(' ',0) + Category as Line,
		Category ,
		Null as manufacturer_code,
		Null as Manufacturer_description,
		Null as Brand_description,
		Null as sku_description,
		0 as lvl
	From Dictionary
	WHERE Category = 'Total Buillon and Savoury'
	GROUP BY Category

	UNION ALL

	SELECT 
		Replicate(' ',1) + manufacturer_description as Line,
		Category ,
		manufacturer_code as manufacturer_code,
		manufacturer_description as Manufacturer_description,
		Null as Brand_description,
		Null as sku_description,
		1 as lvl
	From Dictionary
	WHERE Category = 'Total Buillon and Savoury'
	GROUP BY Category, manufacturer_code, manufacturer_description

	UNION ALL

	SELECT 
		Replicate(' ',2) + brand_description as Line,
		Category ,
		manufacturer_code as manufacturer_code,
		manufacturer_description as Manufacturer_description,
		brand_description as Brand_description,
		Null as sku_description,
		2 as lvl
	From Dictionary
	WHERE Category = 'Total Buillon and Savoury'
	GROUP BY Category, manufacturer_code, manufacturer_description,brand_description

	UNION ALL

	SELECT 
		Replicate(' ',4) + sku_description as Line,
		Category ,
		manufacturer_code as manufacturer_code,
		manufacturer_description as Manufacturer_description,
		brand_description as Brand_description,
		sku_description as sku_description,
		3 as lvl
	From Dictionary
	WHERE Category = 'Total Buillon and Savoury'
	GROUP BY Category, manufacturer_code, manufacturer_description,brand_description,sku_description
)
--------------------------------------------------------------------
3 -- Select the final view of the Report
--------------------------------------------------------------------
SELECT Line
from AllLevels
ORDER BY
	Category,
	manufacturer_code,
	manufacturer_description,
	brand_description,
	sku_description 
