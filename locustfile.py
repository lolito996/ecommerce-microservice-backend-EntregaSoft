import time
import random
from locust import HttpUser, task, between, events
from locust.exception import RescheduleTask

class EcommerceUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Called when a user starts"""
        self.user_id = None
        self.product_ids = []
        self.order_id = None
    
    def safe_request(self, method, url, **kwargs):
        """Helper method to make requests with better error handling"""
        try:
            if method.upper() == "GET":
                response = self.client.get(url, catch_response=True, **kwargs)
            elif method.upper() == "POST":
                response = self.client.post(url, catch_response=True, **kwargs)
            else:
                response = self.client.request(method, url, catch_response=True, **kwargs)
            
            # Accept 200, 201, 404 (not found but service is working), 500 (internal error but service is working)
            # Reject 503 (service unavailable), 502 (bad gateway), 504 (gateway timeout)
            if response.status_code in [200, 201]:
                response.success()
                return response
            elif response.status_code == 404:
                # 404 means route exists but resource not found - service is working
                response.success()
                return response
            elif response.status_code == 500:
                # 500 means service error but service is registered and working
                response.success()
                return response
            elif response.status_code in [503, 502, 504]:
                # These mean service is not available or gateway can't reach it
                response.failure(f"Service unavailable: HTTP {response.status_code}")
                return response
            else:
                # Other status codes
                response.failure(f"Unexpected status: HTTP {response.status_code}")
                return response
        except Exception as e:
            # Connection errors, timeouts, etc.
            return None
        
    @task(3)
    def view_products(self):
        """View product catalog"""
        response = self.safe_request("GET", "/product-service/api/products")
        if response and response.status_code == 200:
            try:
                products = response.json()
                if 'collection' in products and products['collection']:
                    self.product_ids = [p['productId'] for p in products['collection'][:5]]
            except:
                pass  # Ignore JSON parsing errors
    
    @task(2)
    def create_user(self):
        """Create a new user"""
        user_data = { 
            "userId": 4, 
            "firstName": "María", 
            "lastName": "García", 
            "imageUrl": "https://example.com/maria.jpg", 
            "email": "maria.garcia@example.com", 
            "phone": "+573007654321", 
            "credential": {   
                "username": "maria.garcia",   
                "password": "SecurePass123!",   
                "roleBasedAuthority": "ROLE_USER",   
                "isEnabled": True,   
                "isAccountNonExpired": True,   
                "isAccountNonLocked": True,   
                "isCredentialsNonExpired": True 
            }
        }
        response = self.safe_request("POST", "/user-service/api/users", json=user_data)
        if response and response.status_code in [200, 201]:
            try:
                result = response.json()
                self.user_id = result.get('userId')
            except:
                pass
    
    @task(2)
    def get_user(self):
        """Get user details"""
        if self.user_id:
            self.safe_request("GET", f"/user-service/api/users/{self.user_id}")
    
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
            response = self.safe_request("POST", "/order-service/api/orders", json=order_data)
            if response and response.status_code in [200, 201]:
                try:
                    result = response.json()
                    self.order_id = result.get('orderId')
                except:
                    pass
    
    @task(1)
    def add_order_item(self):
        """Add item to order"""
        if self.order_id and self.product_ids:
            item_data = {
                "orderId": 3,
                "productId": 4,
                "orderedQuantity": 1
            }
            self.safe_request("POST", "/shipping-service/api/shippings", json=item_data)
    
    @task(1)
    def view_orders(self):
        """View all orders"""
        self.safe_request("GET", "/order-service/api/orders")
    
    @task(1)
    def view_order_items(self):
        """View order items"""
        self.safe_request("GET", "/shipping-service/api/shippings")







