/*******************************************
## Date: 07/02/2024
## Indicator: 0_Rate_of_something_in_the_population
## Author: Chris Mainey, BSOL ICB
## Description: FIrst processess the data into temp table #1_prep
## Then inserts aggregated values in the final table

********************************************/

/*Preparation*/

Select column1
       , column2
       , column3
into # #1_prep
From [table1] inner join [table2] on table1.column4 = table2.column1
Where [criteria] = "Something"





/*Insert to table*/

Insert into [dbo].[Indicators_main]

SELECT 1 as IndicatorID
count(*)
Geography
from #1_prep
