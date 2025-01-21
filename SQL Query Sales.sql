---To Ensure if the freight paid by company or customers
SELECT 
  OrderID, 
  Freight, 
  TotalDue, 
  CASE WHEN Freight + TaxAmt > 0 
  AND TotalDue = LineTotal THEN 'Paid by Company' ELSE 'Paid by Customer' END AS ShippingResponsibility 
FROM 
  Orders;
--- the shipping on the customer

========================================

---Which products contribute the most to the total revenue, and what percentage of the total revenue do they represent?

With Total AS (
  Select 
    p.ProductID, 
    Product, 
    SUM(TotalDue) AS TotalDue
  from 
    Orders o 
    Left Join Product p on p.ProductID = o.ProductID 
  Group BY 
    Product, 
    p.ProductID
),

TotalRevenue AS (
  Select 
    SUM(TotalDue) AS TotalDue 
  From 
    Total
)

Select TOP 10
   t.Product,
   t.TotalDue,
   Concat((Round(t.TotalDue/R.TotalDue,4)*100),'%') AS Percent_Of_Due 
 From Total t
   Cross join  TotalRevenue  R
Order by 
   t.TotalDue DESC

================================================================
---What is the max 2 total tax revenue generated for products shipped by each shipping method?

Select Top 2  
        ShipMethod,
        Round(Sum(TaxAmt),2) AS TAX,
        Round(Sum(Freight),2) AS Freight,
        Round(Sum(TotalDue),2) AS Due
From 
    ShipMethod a
Left join 
    Orders o  on  a.ShipMethodID = o.ShipMethodID 
Group by 
    a.ShipMethod
Order by 
    TAX  Desc

================================================================
---Analysis the distribution of products with low Tax costs (e.g., below the median) and
---their respective contribution to total revenue.

With Tax_Per_Product AS (
  select 
    p.ProductID,
    p.product, 
    Round(Sum(TaxAmt),2) AS Tax 
  from 
    product p 
    left join Orders o on p.ProductID = o.ProductID 
  Group by 
    p.ProductID, product
), 
Median AS (
  SELECT 
     PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Tax) Over() AS Median 
  FROM 
    Tax_Per_Product
) 
select 
  t.product, 
  t.Tax, 
  Round(SUM(o.TotalDue),2) AS TotalDue 
From 
  Tax_Per_Product t 
join 
  Orders o On  t.ProductID =  o.ProductID 
WHERE 
  t.Tax < (SELECT TOP 1 Median FROM Median)
Group by 
  t.product, 
  t.Tax  
Order by 
 TotalDue DESC
================================================================

 --- Product and shipping analysis 
Select 
  p.Product, 
  OrderQTy, 
  Round(UnitPrice, 2) AS UnitPrice, 
  Round(LineTotal, 2) AS LineTotal, 
  Round(TaxAmt, 2) AS TaxAmt, 
  Round(Freight, 2) AS Freight, 
  Round(TotalDue, 2) AS TotalDue, 
  OnlineOrderFlag,
  OrderDate, 
  DueDate, 
  ShipDate, 
  S.ShipMethod
From 
  Orders o 
  Left join Product p on p.ProductID = o.ProductID 
  Left Join ShipMethod s on o.ShipMethodID = s.ShipMethodID 
ORDER BY 
  OrderDate DESC 

========================================================== 

--- SalesPerson Analysis and cleaned
Select 
  * 
FROM 
  Person 

---Clean title (Uncompleted Column)
Alter Table 
  Person 
Drop 
  Column Title;


---Extract Sales Person Information 
With SALES AS (
  Select 
    p.SalesPersonID, 
    FullName, 
    Round(SUM(o.TotalDue),3) AS TotalDue, 
    City, 
    CountryRegionName, 
    StateProvinceName, 
    PhoneNumberType, 
    count(o.OrderID) AS OrdersNumber
  FROM 
    Person p 
    Left join Orders o on p.SalesPersonID = o.SalesPersonID 
  Group BY 
    p.SalesPersonID, 
    FullName, 
    city, 
    CountryRegionName, 
    StateProvinceName, 
    PhoneNumberType
) 
Select
  SalesPersonID, 
  c.FullName, 
  c.TotalDue, 
  c.City, 
  c.CountryRegionName, 
  c.StateProvinceName, 
  c.PhoneNumberType, 
  OrdersNumber 
From 
  SALES C
Order BY 
  SalesPersonID

 =============================

---Identify the top 5 products with the highest average tax amount per unit sold.

WITH Average_Tax As (
  Select ProductID, 
         UnitPrice ,
         Round(AVG(TaxAmt),3) AS TotalTax 
  from 
    orders 
  Group by 
    ProductID, 
    UnitPrice 
)

SELECT 
  top 5 product, 
  TotalTax 
from 
  product p 
  Left join Average_Tax a on a.ProductID = p.ProductID 
order by 
  TotalTax DESC

=====================================================

---For orders placed online, what is the trend in total revenue over time?

select 
  Year(OrderDate) AS Year, 
  Month(OrderDate) AS Month, 
  Sum(TotalDue) AS TotlDue 
From 
  orders 
Where 
  OnlineOrderFlag = 1 
Group by 
  Year(OrderDate), 
  Month(OrderDate)

========================================================
---For each product, calculate the ratio of freight cost to line total 
---and identify the products from higest ratio to the lowest 

With Freight_Per_Product as(
  select 
    p.Product, 
    Sum(Freight) AS Freight, 
    Sum(Linetotal) AS Linetotal 
  from 
    Orders o 
    Left join Product p on o.ProductID = p.ProductID 
  Group by 
    Product
) 
Select  
    Product , 
    Concat(Round((Freight / Linetotal)* 100,3),'%') AS Ratio_Freight_to_LineTotal
From 
    Freight_Per_Product
Order by 
    Ratio_Freight_to_LineTotal DESC 

