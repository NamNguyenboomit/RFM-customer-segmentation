-- sort customer have in database
With customer as (
    Select *
    From Customer_Transaction
    Where CustomerID in (
        Select distinct 
            id 
        From Customer_Registered
    )
), customer_notindatabase as (
    Select *
    From Customer_Transaction
    Where CustomerID not in (
        Select distinct 
            id 
        From Customer_Registered
    ) or CustomerID = 0
), customer_register_2 as (
-- create how many years date register
Select 
   *,
   datediff(year, created_date, DATEFROMPARTS(2022,09,01)) as year_register
From Customer_Registered
Where stopdate is null or (year(stopdate) >= 2022 and month(stopdate) >= 9)
), RFM_each_val as (
-- Create RFM value
Select distinct
    c.CustomerID, l.LocationName, cr2.year_register,
    DATEDIFF(day, max(Purchase_Date), DATEFROMPARTS(2022,09,01)) as Recency,
    cast(coalesce(round(CAST(count(*) AS decimal(4,3)) / cr2.year_register,3),0) as decimal(4,3)) as Frequency,
    sum(GMV) as Monetary,
    round(sum(GMV) / count(CustomerID), 0) as AOV
From customer as c 
Inner Join customer_register_2 as cr2 
On c.CustomerID = cr2.ID
Inner Join Location as l 
On l.LocationID = cr2.LocationID and l.BranchCode = cr2.BranchCode
Group By c.CustomerID, l.LocationName, cr2.year_register
), RFM_rn as (
Select 
    *,
    ROW_NUMBER() Over (order by Recency DESC) as rn_recency,
    ROW_NUMBER() Over (order by Frequency) as rn_frequency,
    ROW_NUMBER() Over (order by Monetary) as rn_monetary
From RFM_each_val
), RFM_score as (
Select 
  *,
  Case 
    When Recency >= (
        SELECT
            Recency
        From RFM_rn
        Where rn_recency = round(0.25 * (
            Select max(rn_recency)
            From RFM_rn
        ),0) 
    ) and Recency <= (
        SELECT
            max(Recency)
        From RFM_rn
    ) Then 1 
    When Recency < (
        SELECT
            Recency
        From RFM_rn
        Where rn_recency = round(0.25 * (
            Select max(rn_recency)
            From RFM_rn
        ),0)
    ) and Recency >= (
        SELECT
            Recency
        From RFM_rn
        Where rn_recency = round(0.5 * (
            Select max(rn_recency)
            From RFM_rn
        ),0)
    ) Then 2
    When Recency < (
        SELECT
            Recency
        From RFM_rn
        Where rn_recency = round(0.5 * (
            Select max(rn_recency)
            From RFM_rn
        ),0)
    ) and Recency >= (
        SELECT
            Recency
        From RFM_rn
        Where rn_recency = round(0.75 * (
            Select max(rn_recency)
            From RFM_rn
        ),0)
    ) Then 3
    Else 4 End as Recency_score,
    Case 
    When Frequency <= (
        SELECT
            Frequency
        From RFM_rn
        Where rn_frequency = round(0.25 * (
            Select max(rn_frequency)
            From RFM_rn
        ),0) 
    ) and Frequency >= (
        SELECT
            min(Frequency)
        From RFM_rn
    ) Then 1 
    When Frequency > (
        SELECT
            Frequency
        From RFM_rn
        Where rn_frequency = round(0.25 * (
            Select max(rn_frequency)
            From RFM_rn
        ),0)
    ) and Frequency <= (
        SELECT
            Frequency
        From RFM_rn
        Where rn_frequency = round(0.5 * (
            Select max(rn_frequency)
            From RFM_rn
        ),0)
    ) Then 2
    When Frequency > (
        SELECT
            Frequency
        From RFM_rn
        Where rn_frequency = round(0.5 * (
            Select max(rn_frequency)
            From RFM_rn
        ),0)
    ) and Frequency <= (
        SELECT
            Frequency
        From RFM_rn
        Where rn_frequency = round(0.75 * (
            Select max(rn_frequency)
            From RFM_rn
        ),0)
    ) Then 3
    Else 4 End as Frequency_score,
    Case 
    When Monetary <= (
        SELECT
            Monetary
        From RFM_rn
        Where rn_monetary = round(0.25 * (
            Select max(rn_monetary)
            From RFM_rn
        ),0) 
    ) and Monetary >= (
        SELECT
            min(Monetary)
        From RFM_rn
    ) Then 1 
    When Monetary > (
        SELECT
            Monetary
        From RFM_rn
        Where rn_monetary = round(0.25 * (
            Select max(rn_monetary)
            From RFM_rn
        ),0)
    ) and Monetary <= (
        SELECT
            Monetary
        From RFM_rn
        Where rn_monetary = round(0.5 * (
            Select max(rn_monetary)
            From RFM_rn
        ),0)
    ) Then 2
    When Monetary > (
        SELECT
            Monetary
        From RFM_rn
        Where rn_monetary = round(0.5 * (
            Select max(rn_monetary)
            From RFM_rn
        ),0)
    ) and Monetary <= (
        SELECT
            Monetary
        From RFM_rn
        Where rn_monetary = round(0.75 * (
            Select max(rn_monetary)
            From RFM_rn
        ),0)
    ) Then 3
    Else 4 End as Monetary_score
From RFM_rn
), RFM_concat as (
Select
    *,
    concat(Recency_score, Frequency_score, Monetary_score) as RFM_value
From RFM_score
), RFM_segmentation as (
Select
    *,
    Case 
        When RFM_value in (444) then 'Champion'
        When RFM_value in (414, 424, 314, 324, 344, 334, 434) then 'Loyal'
        When RFM_value in (114, 124) then 'At risk'
        When RFM_value in (214, 224) then 'Potential'
        Else 'Others'
    End as Segmentation
From RFM_concat
)

Select top 500
    *
From customer_notindatabase
