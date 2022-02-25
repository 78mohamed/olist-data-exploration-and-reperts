-- category_name vs price and properties

select p.category_name , o.price , p.product_weight , p.product_width , p.product_length , p.product_height
from Product p, [dbo].[Order] o
where p.product_id = o.product_id

/*___________________________________________________________________________________________*/

-- highest catigory price
select top 1 p.category_name ,  o.price
from Product p, [dbo].[Order] o
where p.product_id = o.product_id
order by  o.price desc

/*____________________________________________________________________________________________*/

--customer, product and review
select p.category_name , o.review_score , o.review_comment_title , o.review_comment_message
from Product p, [dbo].[Order] o , [dbo].[Customer] c
where p.product_id = o.product_id and o.customer_id = c.customer_id

/*____________________________________________________________________________________________*/
--customer and city
select c.customer_id , c.customer_city
from [dbo].[Customer] c

/*___________________________________________________________________________________________*/
-- seller and city
select s.seller_id , s.seller_city
from Seller s

/*_____________________________________________________________________________*/
select p.category_name  , max(p.product_weight)
from Product p, [dbo].[Order] o
where p.product_id = o.product_id
group by p.category_name