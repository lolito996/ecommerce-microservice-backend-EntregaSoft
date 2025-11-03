import time
import random
from locust import HttpUser, task, between

class EcommerceUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Called when a user starts"""
        self.user_id = None
        self.product_ids = []
        self.order_id = None
        
    @task(3)
    def view_products(self):
        """View product catalog"""
        response = self.client.get("/product-service/api/products")
        if response.status_code == 200:
            products = response.json()
            if 'collection' in products and products['collection']:
                self.product_ids = [p['productId'] for p in products['collection'][:5]]
    
    @task(2)
    def create_user(self):
        """Create a new user"""
        user_data = { "userId": 4, "firstName": "María", "lastName": "García", "imageUrl": "https://example.com/maria.jpg", "email": "maria.garcia@example.com", "phone": "+573007654321", "credential": {   "username": "maria.garcia",   "password": "SecurePass123!",   "roleBasedAuthority": "ROLE_USER",   "isEnabled": True,   "isAccountNonExpired": True,   "isAccountNonLocked": True,   "isCredentialsNonExpired": True }}
        response = self.client.post("/user-service/api/users", json=user_data)
        if response.status_code == 200:
            self.user_id = response.json().get('userId')
    
    @task(2)
    def get_user(self):
        """Get user details"""
        if self.user_id:
            self.client.get(f"/user-service/api/users/{self.user_id}")
    
    @task(1)
    def create_order(self):
        """Create an order"""
        if self.user_id:
            order_data = {
                "orderId": 3,
                "orderDesc": "Complete shopping order",
                "orderFee": 1029.98,
                "cart": {
                    "cartId": 3
                }
            }
            response = self.client.post("/order-service/api/orders", json=order_data)
            if response.status_code == 200:
                self.order_id = response.json().get('orderId')
    
    @task(1)
    def add_order_item(self):
        """Add item to order"""
        if self.order_id and self.product_ids:
            item_data = {
                "orderId": 3,
                "productId": 4,
                "orderedQuantity": 1
            }
            self.client.post("/shipping-service/api/shippings", json=item_data)
    
    @task(1)
    def view_orders(self):
        """View all orders"""
        self.client.get("/order-service/api/orders")
    
    @task(1)
    def view_order_items(self):
        """View order items"""
        self.client.get("/shipping-service/api/shippings")

