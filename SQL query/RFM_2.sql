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
)

Select 
    *
From customer_notindatabase 