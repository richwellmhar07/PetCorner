from flask import Flask, jsonify, request, session
from flask_mail import Mail, Message
from index import get_db_connection 
from mysql.connector import Error
from datetime import datetime
from decimal import Decimal
from flask_cors import CORS
import mysql.connector
from PIL import Image
import bcrypt 
import random
import string
import base64
import jwt
import io



app = Flask(__name__, static_url_path='/static', static_folder='static')

CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)
app.secret_key = 'your_secret_key'  # Secure session management

# Gmail SMTP configuration
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USE_SSL'] = False
app.config['MAIL_USERNAME'] = 'petcorner999@gmail.com' 
app.config['MAIL_PASSWORD'] = 'znvo uect zpsa wtmv'    
app.config['MAIL_DEFAULT_SENDER'] = 'petcorner999@gmail.com' 

mail = Mail(app)
verification_codes = {}

# Login Function .................................................................................
# Login Original Route DON'T DELETE! .............................................................
# @app.route('/api/login', methods=['POST'])
# def login_api():
#     data = request.json
#     username_or_email = data.get('username')
#     password = data.get('password')

#     if not username_or_email or not password:
#         return jsonify({"error": "Username and password are required"}), 400

#     conn = get_db_connection()
#     cursor = conn.cursor(dictionary=True)

#     # Check buyer
#     cursor.execute("""
#         SELECT user_id, password FROM buyer_information
#         WHERE username = %s OR email = %s
#     """, (username_or_email, username_or_email))
#     buyer = cursor.fetchone()

#     if buyer and bcrypt.checkpw(password.encode('utf-8'), buyer['password'].encode('utf-8')):
#         cursor.close()
#         conn.close()
#         return jsonify({"message": "Login successful", "user_id": buyer['user_id'], "role": "buyer"}), 200

#     # Check courier
#     cursor.execute("""
#         SELECT courier_id, password FROM courier_info
#         WHERE username = %s OR email = %s
#     """, (username_or_email, username_or_email))
#     courier = cursor.fetchone()

#     cursor.close()
#     conn.close()

#     if courier and bcrypt.checkpw(password.encode('utf-8'), courier['password'].encode('utf-8')):
#         return jsonify({"message": "Login successful", "user_id": courier['courier_id'], "role": "courier"}), 200

#     return jsonify({"error": "Invalid username or password"}), 401

# Login Temporary Route, For Testing. DON'T DELETE!...............................................
@app.route('/api/login', methods=['POST'])
def login_api():
    data = request.json
    username_or_email = data.get('username')
    password = data.get('password')

    if not username_or_email or not password:
        return jsonify({"error": "Username and password are required"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT user_id, 'buyer' AS role FROM buyer_information
        WHERE (username = %s OR email = %s) AND password = %s
    """, (username_or_email, username_or_email, password))
    buyer = cursor.fetchone()

    cursor.execute("""
        SELECT courier_id, 'courier' AS role FROM courier_info
        WHERE (username = %s OR email = %s) AND password = %s
    """, (username_or_email, username_or_email, password))
    courier = cursor.fetchone()

    cursor.close()
    conn.close()

    if buyer:
        return jsonify({"message": "Login successful", "user_id": buyer['user_id'], "role": "buyer"}), 200
    elif courier:
        return jsonify({"message": "Login successful", "user_id": courier['courier_id'], "role": "courier"}), 200
    else:
        return jsonify({"error": "Invalid username or password"}), 401

# Sending Code to Email ..........................................................................
@app.route('/send_verification_code', methods=['POST'])
def send_verification_code():
    data = request.json
    email = data.get('email')

    if not email:
        return jsonify({'error': 'Email is required'}), 400

    code = ''.join(random.choices(string.digits, k=6))

    verification_codes[email] = code

    msg = Message('Your Verification Code', recipients=[email])
    msg.body = f'Your verification code is: {code}'
    mail.send(msg)

    return jsonify({'message': 'Verification code sent successfully'}), 200

# Verifying Code Sent to Gmail ...................................................................
@app.route('/verify_code', methods=['POST'])
def verify_code():
    data = request.json
    email = data.get('email')
    code = data.get('code')

    if not email or not code:
        return jsonify({'error': 'Email and code are required'}), 400

    stored_code = verification_codes.get(email)

    if stored_code == code:
        return jsonify({'message': 'Email verified successfully!'}), 200
    else:
        return jsonify({'error': 'Invalid verification code'}), 400

# Checking Email Existence........................................................................
@app.route('/check_email_existence', methods=['GET', 'POST']) 
def check_email_existence():
    if request.method == 'GET':
        return jsonify({'message': 'Use POST to check email existence.'})

    data = request.get_json()
    email = data.get('email')

    if email == "test@example.com":
        return jsonify({'exists': True})
    else:
        return jsonify({'exists': False})

# Signup User Registration........................................................................
@app.route('/register_user', methods=['POST'])
def register_user():
    data = request.json
    email = data.get('email')
    username = data.get('username')
    password = data.get('password')
    role = data.get('role')

    if not email or not username or not password or not role:
        return jsonify({'error': 'All fields are required'}), 400

    # Only process buyer registrations in this route
    if role != "buyer":
        return jsonify({'error': 'This route is for buyer registration only'}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    # Check if email already exists
    cursor.execute("SELECT * FROM buyer_information WHERE email = %s", (email,))
    if cursor.fetchone():
        cursor.close()
        conn.close()
        return jsonify({'error': 'Email already registered'}), 409  # 409 Conflict status code

    try:
        # Hash the password using bcrypt
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

        # Insert only buyer information with hashed password
        cursor.execute("""
            INSERT INTO buyer_information (email, username, password)
            VALUES (%s, %s, %s)
        """, (email, username, hashed_password))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'Buyer registered successfully!'}), 201
    except Exception as e:
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({'error': f'Registration failed: {str(e)}'}), 500

# Showing Products................................................................................
@app.route('/api/products', methods=['GET'])
def get_all_products():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT p.productid, p.productname, p.productimage, p.productprice, p.productstocks, 
                   p.product_quality, p.feedback, p.productdescription, p.productcategory,
                   s.shopname, s.seller_id
            FROM products p
            JOIN seller_information s ON p.seller_id = s.seller_id
        """
        cursor.execute(query)
        products = cursor.fetchall()
        cursor.close()
        conn.close()

        for product in products:
            if product['productimage'] and not product['productimage'].startswith("http"):
                product['productimage'] = f"http://192.168.1.19:5000/static/images/{product['productimage']}"

        return jsonify(products), 200

    except Exception as e:
        print("Error in /api/products:", e)
        return jsonify({'error': 'Failed to fetch products'}), 500
    
# Fetching Cart Details ..........................................................................
@app.route('/api/get_cart', methods=['POST'])
def get_cart_mobile():
    try:
        data = request.get_json()
        user_id = data.get('user_id')

        if not user_id:
            return jsonify({'error': 'User ID is required'}), 400

        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT 
                cart.cartid, 
                cart.productid, 
                cart.productname, 
                cart.productimage, 
                cart.productprice, 
                cart.productqty, 
                cart.shopname, 
                cart.seller_id,
                products.productstocks  
            FROM cart
            JOIN products ON cart.productid = products.productid
            WHERE cart.user_id = %s
            ORDER BY cart.cartid DESC
        """, (user_id,))
        cart_items = cursor.fetchall()

        # Format image URLs if needed
        for item in cart_items:
            if item['productimage'] and not item['productimage'].startswith("http"):
                item['productimage'] = f"http://192.168.1.19:5000/static/images/{item['productimage']}"

        # Calculate subtotal
        subtotal = sum(item['productprice'] * item['productqty'] for item in cart_items)

        cursor.close()
        conn.close()

        return jsonify({
            'cart_items': cart_items,
            'subtotal': subtotal
        }), 200

    except Exception as e:
        print("Error in /api/get_cart:", e)
        return jsonify({'error': 'Failed to load cart'}), 500

# Updating Product Qty in the Cart................................................................
@app.route('/update_cart_quantity', methods=['POST']) 
def update_cart_quantity():
    data = request.get_json()
    cartid = data.get('cartid')
    quantity = int(data.get('quantity'))

    if not cartid or quantity is None:
        return jsonify({'success': False, 'error': 'Invalid cart ID or quantity'})

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)  # dictionary=True!

    try:
        # Get the product ID from the cart
        cursor.execute("SELECT productid FROM cart WHERE cartid = %s", (cartid,))
        product = cursor.fetchone()
        if not product:
            return jsonify({'success': False, 'error': 'Product not found in cart'})

        product_id = product['productid'] 

        # Get the available stock from the products table
        cursor.execute("SELECT productstocks FROM products WHERE productid = %s", (product_id,))
        stock = cursor.fetchone()
        if not stock:
            return jsonify({'success': False, 'error': 'Stock information unavailable'})

        available_stock = stock['productstocks']  
        # Ensure requested quantity does not exceed available stock
        if quantity > available_stock:
            return jsonify({'success': False, 'error': 'Requested quantity exceeds available stock', 'max_stock': available_stock})

        # Update the quantity in the cart
        cursor.execute("""
            UPDATE cart
            SET productqty = %s
            WHERE cartid = %s
        """, (quantity, cartid))
        conn.commit()

        # Re-fetch the updated cart item
        cursor.execute("""
            SELECT cartid, productid, productname, productimage, productprice, productqty, shopname, seller_id
            FROM cart
            WHERE cartid = %s
        """, (cartid,))
        updated_item = cursor.fetchone()

        if updated_item:
            if updated_item['productimage'] and not updated_item['productimage'].startswith("http"):
                updated_item['productimage'] = f"http://192.168.1.19:5000/static/images/{updated_item['productimage']}"

        return jsonify({'success': True, 'updated_item': updated_item, 'updated_quantity': quantity})

    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'error': str(e)})

    finally:
        cursor.close()
        conn.close()

# Delete Product in the Cart .....................................................................
@app.route('/delete_cart_item', methods=['POST'])
def delete_cart_item():
    data = request.get_json()
    cartid = data.get('cartid')

    if not cartid:
        return jsonify({'success': False, 'error': 'Invalid cart ID'})

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("DELETE FROM cart WHERE cartid = %s", (cartid,))
        conn.commit()

        return jsonify({'success': True})
    
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'error': str(e)})
    
    finally:
        cursor.close()
        conn.close()

# Adding Products to the Cart ....................................................................
@app.route('/api/cart/add', methods=['POST'])
def add_to_cart_api():
    try:
        data = request.get_json()
        
        # Extract data from request
        user_id = data.get('user_id')
        product_id = data.get('product_id')
        product_name = data.get('product_name')
        product_price = float(data.get('product_price'))  # Convert to float
        product_qty = int(data.get('product_qty'))  # Convert to int
        shop_name = data.get('shop_name')
        seller_id = data.get('seller_id')
        product_image = data.get('product_image')  # This is a URL, not base64
        
        # Validate required fields
        if not all([user_id, product_id, product_name, product_price, product_qty, shop_name, seller_id, product_image]):
            missing_fields = [field for field in ['user_id', 'product_id', 'product_name', 'product_price', 
                                                 'product_qty', 'shop_name', 'seller_id', 'product_image'] 
                              if not data.get(field)]
            return jsonify({'error': f'Missing required fields: {", ".join(missing_fields)}'}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Check if the product exists and get available stock
        cursor.execute(
            "SELECT productstocks FROM products WHERE productid = %s",
            (product_id,)
        )
        stock_result = cursor.fetchone()
        
        if not stock_result:
            return jsonify({'error': 'Product not found'}), 404
            
        available_stock = stock_result['productstocks']
        
        # Check if product already exists in user's cart
        cursor.execute(
            "SELECT cartid, productqty FROM cart WHERE user_id = %s AND productid = %s",
            (user_id, product_id)
        )
        existing_product = cursor.fetchone()
        
        if existing_product:
            new_quantity = existing_product['productqty'] + product_qty
            
            if new_quantity > available_stock:
                return jsonify({
                    'error': 'Cannot add more than available stock', 
                    'max_stock': available_stock
                }), 400
                
            cursor.execute(
                """
                UPDATE cart 
                SET productqty = %s 
                WHERE cartid = %s
                """,
                (new_quantity, existing_product['cartid'])
            )
            message = 'Product quantity updated in cart'
        else:
            if product_qty > available_stock:
                return jsonify({
                    'error': 'Cannot add more than available stock', 
                    'max_stock': available_stock
                }), 400
                
            cursor.execute(
                """
                INSERT INTO cart (user_id, productid, productname, productprice, productqty, productimage, shopname, seller_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (user_id, product_id, product_name, product_price, product_qty, product_image, shop_name, seller_id)
            )
            message = 'Product added to cart successfully'
            
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': message, 'success': True}), 200
        
    except Exception as e:
        print(f"Error in /api/cart/add: {str(e)}")
        return jsonify({'error': f'Failed to add product to cart: {str(e)}'}), 500

# Submitting Courier Application .................................................................
@app.route('/api/courier_application', methods=['POST'])
def submit_courier_application():
    try:
        # Get form data
        data = request.form.to_dict()
        
        # Extract basic information
        username = data.get('username')
        password = data.get('password')
        email = data.get('email')
        first_name = data.get('first_name')
        last_name = data.get('last_name')
        middle_name = data.get('middle_name', '')  # Optional field
        province = data.get('province')
        municipality = data.get('municipality')
        barangay = data.get('barangay')
        postal_code = data.get('postal_code')
        date_of_birth = data.get('date_of_birth')
        sex = data.get('sex')
        plate_number = data.get('plate_number')
        
        # Validate required fields
        required_fields = ['username', 'password', 'email', 'first_name', 'last_name', 
                          'province', 'municipality', 'barangay', 'postal_code', 
                          'date_of_birth', 'sex', 'plate_number']
        
        missing_fields = [field for field in required_fields if not data.get(field)]
        if missing_fields:
            return jsonify({
                'success': False, 
                'error': f'Missing required fields: {", ".join(missing_fields)}'
            }), 400
            
        # Check for files
        if 'license_image' not in request.files or 'selfie_image' not in request.files:
            return jsonify({
                'success': False, 
                'error': 'Both license image and selfie image are required'
            }), 400
            
        license_file = request.files['license_image']
        selfie_file = request.files['selfie_image']
        
        # Process image files - this helps with handling large files
        # Optional: Further compression on server side using Pillow
        try:
            
            # Process license image
            license_img = Image.open(license_file)
            license_buffer = io.BytesIO()
            license_img.save(license_buffer, format='JPEG', quality=70)
            license_blob = license_buffer.getvalue()
            
            # Process selfie image
            selfie_img = Image.open(selfie_file)
            selfie_buffer = io.BytesIO()
            selfie_img.save(selfie_buffer, format='JPEG', quality=70)
            selfie_blob = selfie_buffer.getvalue()
        except ImportError:
            # If Pillow is not installed, read files directly
            license_blob = license_file.read()
            selfie_blob = selfie_file.read()
        
        # Get current datetime
        import datetime
        application_date = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        # Connect to database
        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            # Use a transaction for safety
            cursor.execute("START TRANSACTION")
            
            # Insert into courier_application table - store file paths instead of blobs
            query = """
                INSERT INTO courier_info (
                    username, password, email, first_name, last_name, middle_name,
                    province, municipality, barangay, postal_code, date_of_birth,
                    sex, plate_number, license_image, selfie_image, application_date
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            cursor.execute(query, (
                username, password, email, first_name, last_name, middle_name,
                province, municipality, barangay, postal_code, date_of_birth,
                sex, plate_number, license_blob, selfie_blob, application_date
            ))
            
            # Commit the transaction
            cursor.execute("COMMIT")
            
            return jsonify({
                'success': True,
                'message': 'Application submitted successfully. We will review your application and notify you via email.'
            }), 201
            
        except Exception as db_error:
            # Rollback in case of error
            cursor.execute("ROLLBACK")
            raise db_error
            
    except Exception as e:
        print(f"Error submitting courier application: {str(e)}")
        return jsonify({
            'success': False,
            'error': f'Failed to submit application: {str(e)}'
        }), 500
    finally:
        # Always close cursor and connection
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn:
            conn.close()


@app.route('/api/for_pickup', methods=['GET'])
def for_pickup():
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        query = """
        SELECT 
            order_id,
            shopname,
            seller_address,
            buyer_address,
            date,
            seller_id,
            buyer,
            phonenumber,
            courier_id
        FROM 
            for_pickup
        WHERE 
            status = 'Pending'
        """

        cursor.execute(query)
        orders = cursor.fetchall()
        cursor.close()
        connection.close()

        return jsonify({'status': 'success', 'orders': orders}), 200

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500


# Displaying Orders in Buyer's Page ..............................................................
@app.route('/api/orders', methods=['GET'])
def get_user_orders():
    user_id = request.args.get('user_id')  

    if not user_id:
        return jsonify({'status': 'error', 'message': 'User ID is required'}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    query = """
        SELECT 
            oi.productid,  
            p.productimage,
            p.seller_id,
            oi.productname, 
            oi.productprice,
            oi.productqty, 
            o.total, 
            o.order_id,
            o.ordered_date, 
            o.status,
            o.shipped_date,
            o.received_date
        FROM order_items oi
        JOIN products p ON oi.productid = p.productid 
        JOIN orders o ON oi.order_id = o.order_id  
        WHERE o.user_id = %s
    """


    cursor.execute(query, (user_id,))
    rows = cursor.fetchall()
    conn.close()

    return jsonify({'status': 'success', 'orders': rows}), 200

# Displaying User Info In Account ................................................................
@app.route('/api/get_buyer_account', methods=['POST'])
def get_buyer_account():
    try:
        data = request.get_json()
        user_id = data.get('user_id')

        if not user_id:
            return jsonify({'status': 'error', 'message': 'Missing user_id'}), 400

        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        query = """
            SELECT user_id, name, username, email, password, phonenumber, birthday, gender, address, profile 
            FROM buyer_information 
            WHERE user_id = %s
        """
        cursor.execute(query, (user_id,))
        user = cursor.fetchone()

        cursor.close()
        conn.close()

        if user:
            # Convert BLOB profile image to base64 if needed
            if user['profile']:
                import base64
                user['profile'] = base64.b64encode(user['profile']).decode('utf-8')

            return jsonify({'status': 'success', 'data': user})
        else:
            return jsonify({'status': 'error', 'message': 'User not found'}), 404

    except Error as e:
        print("Error while connecting to MySQL", e)
        return jsonify({'status': 'error', 'message': 'Database error'}), 500

# Updating Buyer's Info In Account ...............................................................
@app.route('/api/update_buyer_info', methods=['POST'])
def update_buyer_info():
    data = request.get_json()
    user_id = data.get('user_id')
    update_fields = {}
    
    # Debug logging
    print(f"Received data: {data}")

    if not user_id:
        return jsonify({'success': False, 'message': 'Missing user ID.'}), 400

    # Build a dictionary of fields to update
    if 'name' in data:
        update_fields['name'] = data['name']
    if 'username' in data:
        update_fields['username'] = data['username']
    if 'phonenumber' in data:
        update_fields['phonenumber'] = data['phonenumber']
    if 'email' in data:
        update_fields['email'] = data['email']
    if 'gender' in data:
        update_fields['gender'] = data['gender']
    if 'birthday' in data:
        update_fields['birthday'] = data['birthday']
        print(f"Adding birthday to update: {data['birthday']}")
    if 'address' in data:
        update_fields['address'] = data['address']
    
    # Debug logging
    print(f"Fields to update: {update_fields}")

    if not update_fields:
        return jsonify({'success': False, 'message': 'No fields to update.'}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Check for existing username, phonenumber, and email.
        if 'username' in update_fields:
            new_username = update_fields['username']
            cursor.execute("SELECT COUNT(*) FROM buyer_information WHERE username = %s AND user_id != %s", (new_username, user_id))
            username_count = cursor.fetchone()[0]
            if username_count > 0:
                return jsonify({'success': False, 'message': 'Username already exists.'}), 400

        if 'phonenumber' in update_fields:
            new_phonenumber = update_fields['phonenumber']
            cursor.execute("SELECT COUNT(*) FROM buyer_information WHERE phonenumber = %s AND user_id != %s", (new_phonenumber, user_id))
            phonenumber_count = cursor.fetchone()[0]
            if phonenumber_count > 0:
                return jsonify({'success': False, 'message': 'Phone number already exists.'}), 400

        if 'email' in update_fields:
            new_email = update_fields['email']
            cursor.execute("SELECT COUNT(*) FROM buyer_information WHERE email = %s AND user_id != %s", (new_email, user_id))
            email_count = cursor.fetchone()[0]
            if email_count > 0:
                return jsonify({'success': False, 'message': 'Email already exists.'}), 400

        # Construct the update query
        set_clause = ", ".join([f"{field} = %s" for field in update_fields.keys()])
        values = list(update_fields.values())
        query = f"UPDATE buyer_information SET {set_clause} WHERE user_id = %s"
        values.append(user_id) # Add user_id to the values
        
        # Debug logging
        print(f"SQL Query: {query}")
        print(f"SQL Values: {values}")

        cursor.execute(query, values)
        conn.commit()
        
        # Check if any rows were affected
        rows_affected = cursor.rowcount
        print(f"Rows affected: {rows_affected}")
        
        cursor.close()
        conn.close()
        return jsonify({'success': True, 'message': 'Buyer information updated successfully.'}), 200
    except mysql.connector.Error as err:
        print(f"MySQL Error: {err}")
        return jsonify({'success': False, 'message': f'Database error: {err}'}), 500
    except Exception as e:
        print(f"General Error: {e}")
        return jsonify({'success': False, 'message': f'An error occurred: {e}'}), 500

# Updating Buyer's Profile Image Account .........................................................
@app.route('/api/update_profile_image', methods=['POST'])
def update_profile_image():
    data = request.get_json()
    user_id = data.get('user_id')
    profile_image_base64 = data.get('profile_image')
    
    # Debug logging
    print(f"Received update profile image request for user ID: {user_id}")
    
    if not user_id:
        return jsonify({'success': False, 'message': 'Missing user ID.'}), 400
    
    if not profile_image_base64:
        return jsonify({'success': False, 'message': 'Missing profile image data.'}), 400
    
    try:
        # Convert base64 string to binary data for MySQL BLOB
        profile_image_binary = base64.b64decode(profile_image_base64)
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Update the profile image in the database
        query = "UPDATE buyer_information SET profile = %s WHERE user_id = %s"
        cursor.execute(query, (profile_image_binary, user_id))
        conn.commit()
        
        # Check if any rows were affected
        rows_affected = cursor.rowcount
        print(f"Rows affected: {rows_affected}")
        
        cursor.close()
        conn.close()
        
        if rows_affected > 0:
            return jsonify({
                'success': True, 
                'message': 'Profile image updated successfully.'
            }), 200
        else:
            return jsonify({
                'success': False, 
                'message': 'No changes made. User ID may not exist.'
            }), 404
            
    except mysql.connector.Error as err:
        print(f"MySQL Error: {err}")
        return jsonify({
            'success': False, 
            'message': f'Database error: {err}'
        }), 500
    except Exception as e:
        print(f"General Error: {e}")
        return jsonify({
            'success': False, 
            'message': f'An error occurred: {e}'
        }), 500

# Updating Buyer's Password ......................................................................
@app.route('/api/update_password', methods=['POST'])
def update_password():
    data = request.get_json()
    user_id = data.get('user_id')
    current_password = data.get('current_password')
    new_password = data.get('new_password')
    
    # Debug logging
    print(f"Received password update request for user: {user_id}, type: {type(user_id)}")
    
    # Validate required fields - don't force type conversion
    if not user_id:
        return jsonify({'success': False, 'message': 'Missing user ID.'}), 400
    
    if not all([current_password, new_password]):
        return jsonify({'success': False, 'message': 'Missing required fields.'}), 400
    
    # Validate password complexity requirements
    if (len(new_password) < 8 or not any(char.islower() for char in new_password) 
            or not any(char.isupper() for char in new_password) 
            or not any(char.isdigit() for char in new_password)
            or not any(char in '!@#$%^&*(),.?":{}|<>' for char in new_password)):
        return jsonify({'success': False, 'message': 'New password does not meet complexity requirements.'}), 400
    
    try:
        import bcrypt
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Debug query and parameters
        print(f"Executing query: SELECT password FROM buyer_information WHERE user_id = {user_id}")
        
        # Verify current password is correct
        cursor.execute("SELECT password FROM buyer_information WHERE user_id = %s", (user_id,))
        result = cursor.fetchone()
        
        if not result:
            print(f"User not found with ID: {user_id}")
            return jsonify({'success': False, 'message': 'User not found.'}), 404
        
        stored_password_hash = result[0]
        print(f"Retrieved stored password hash: {stored_password_hash[:10]}... (truncated)")
        
        # Check if current password matches using bcrypt
        try:
            password_match = bcrypt.checkpw(current_password.encode('utf-8'), stored_password_hash.encode('utf-8'))
            print(f"Password match result: {password_match}")
            
            if not password_match:
                return jsonify({'success': False, 'message': 'Current password is incorrect.'}), 401
        except Exception as e:
            print(f"Error during password verification: {e}")
            # If bcrypt verification fails (possibly due to format issues), fall back to direct comparison
            if stored_password_hash != current_password:
                return jsonify({'success': False, 'message': 'Current password is incorrect.'}), 401
        
        # Hash the new password before storing
        try:
            hashed_password = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt())
            hashed_password_str = hashed_password.decode('utf-8')
        except Exception as e:
            print(f"Error hashing new password: {e}")
            # Fallback to storing password directly if hashing fails
            # Note: This is not secure and should be fixed properly
            hashed_password_str = new_password
            print("WARNING: Storing password without proper hashing")
        
        print(f"Updating password for user_id: {user_id}")
        cursor.execute("UPDATE buyer_information SET password = %s WHERE user_id = %s", 
                      (hashed_password_str, user_id))
        conn.commit()
        
        # Check if any rows were affected
        rows_affected = cursor.rowcount
        print(f"Rows affected: {rows_affected}")
        
        cursor.close()
        conn.close()
        
        if rows_affected > 0:
            return jsonify({'success': True, 'message': 'Password updated successfully.'}), 200
        else:
            return jsonify({'success': False, 'message': 'Failed to update password. No records were updated.'}), 500
            
    except mysql.connector.Error as err:
        print(f"MySQL Error: {err}")
        return jsonify({'success': False, 'message': f'Database error: {err}'}), 500
    except Exception as e:
        print(f"General Error: {e}")
        return jsonify({'success': False, 'message': f'An error occurred: {e}'}), 500

# Updating Buyer's Address .......................................................................
@app.route('/api/update_address', methods=['POST'])
def update_address():
    data = request.get_json()
    user_id = data.get('user_id')
    address = data.get('address')
    
    # Debug logging
    print(f"Received address update data: {data}")

    if not user_id:
        return jsonify({'success': False, 'message': 'Missing user ID.'}), 400
    
    if not address:
        return jsonify({'success': False, 'message': 'Missing address data.'}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Update just the address field
        query = "UPDATE buyer_information SET address = %s WHERE user_id = %s"
        values = (address, user_id)
        
        # Debug logging
        print(f"SQL Query: {query}")
        print(f"SQL Values: {values}")

        cursor.execute(query, values)
        conn.commit()
        
        # Check if any rows were affected
        rows_affected = cursor.rowcount
        print(f"Rows affected: {rows_affected}")
        
        if rows_affected == 0:
            cursor.close()
            conn.close()
            return jsonify({'success': False, 'message': 'No buyer found with the given ID.'}), 404
        
        cursor.close()
        conn.close()
        return jsonify({
            'success': True, 
            'message': 'Address updated successfully.',
            'address': address
        }), 200
    except mysql.connector.Error as err:
        print(f"MySQL Error: {err}")
        return jsonify({'success': False, 'message': f'Database error: {err}'}), 500
    except Exception as e:
        print(f"General Error: {e}")
        return jsonify({'success': False, 'message': f'An error occurred: {e}'}), 500

# Placing Order ..................................................................................
@app.route('/api/place_order', methods=['POST'])
def api_place_order():
    data = request.get_json()
    
    # Get data from request body instead of session
    user_id = data.get('user_id')
    total_amount = data.get('total_amount')
    ordered_items = data.get('ordered_items')
    
    if not user_id:
        return jsonify({'success': False, 'message': 'User ID is required'}), 400
    
    if not ordered_items:
        return jsonify({'success': False, 'message': 'Ordered items are required'}), 400

    ordered_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    # Extract seller_id from the first item in the ordered items list
    seller_id = ordered_items[0].get('sellerid') if ordered_items else None

    # Establish DB connection
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Insert into orders table, including seller_id
        cursor.execute("""
            INSERT INTO orders (user_id, total, ordered_date, seller_id) 
            VALUES (%s, %s, %s, %s)
        """, (user_id, total_amount, ordered_date, seller_id))
        conn.commit()

        # Get the last inserted order_id
        cursor.execute("SELECT LAST_INSERT_ID()")
        order_id = cursor.fetchone()[0]

        # Insert each ordered item into order_items table
        for item in ordered_items:
            cursor.execute("""
                INSERT INTO order_items (order_id, productid, productname, productprice, productqty, subtotal, seller_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                order_id, 
                item.get('productid'), 
                item.get('productname'), 
                item.get('productprice'), 
                item.get('productqty'), 
                item.get('subtotal'), 
                item.get('sellerid')
            ))

            # Remove the item from the cart if cartid is provided
            if 'cartid' in item and item['cartid']:
                cursor.execute("DELETE FROM cart WHERE cartid = %s", (item['cartid'],))
        
        conn.commit()

        return jsonify({
            'success': True, 
            'message': 'Order placed successfully!',
            'order_id': order_id
        })

    except Exception as e:
        conn.rollback()  # Rollback in case of error
        return jsonify({'success': False, 'message': str(e)}), 500

    finally:
        cursor.close()
        conn.close()

# Cancel Order Request ...........................................................................
@app.route('/api/cancel-order', methods=['POST'])
def cancel_order():
    data = request.json
    
    # Extract data from request
    order_id = data.get('order_id')
    user_id = data.get('user_id')
    ordered_date = data.get('ordered_date')
    reason = data.get('reason')
    request_date = datetime.now()
    
    try:
        # Insert into database
        conn = get_db_connection()
        cursor = conn.cursor()
        query = """
        INSERT INTO cancel_requests (order_id, user_id, ordered_date, reason, request_date)
        VALUES (%s, %s, %s, %s, %s)
        """
        cursor.execute(query, (order_id, user_id, ordered_date, reason, request_date))
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({"success": True, "message": "Order cancellation request submitted successfully"}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

# Mark Order as Received .........................................................................
@app.route('/api/mark_order_received', methods=['POST'])
def api_mark_order_received():
    data = request.get_json()
    
    # Get order_id from request body
    order_id = data.get('order_id')
    
    if not order_id:
        return jsonify({'success': False, 'message': 'Order ID is required'}), 400

    connection = get_db_connection()
    cursor = connection.cursor()
    
    try:
        # Update order status and received date
        query_update_order = """
            UPDATE orders
            SET status = 'Received', received_date = NOW()
            WHERE order_id = %s
        """
        cursor.execute(query_update_order, (order_id,))

        query_update_order1 = """
            UPDATE for_pickup
            SET status = 'Delivered', received_date = NOW()
            WHERE order_id = %s
        """
        cursor.execute(query_update_order1, (order_id,))

        # Get total and seller ID for the order
        query_get_total = """
            SELECT total, seller_id
            FROM orders
            WHERE order_id = %s
        """
        cursor.execute(query_get_total, (order_id,))
        result = cursor.fetchone()

        if result:
            order_total = Decimal(result[0])  # Ensure total is a Decimal
            seller_id = result[1]

            # Calculate admin commission (10% of total)
            admin_commission = order_total * Decimal('0.10')

            # Seller income is the total after subtracting admin commission
            seller_income = order_total - admin_commission

            # Check and update admin commission table
            query_check_commission = """
                SELECT seller_income, admin_income
                FROM admin_commission
                WHERE seller_id = %s
            """
            cursor.execute(query_check_commission, (seller_id,))
            existing_commission = cursor.fetchone()

            if existing_commission:
                # Convert existing_commission values to Decimal if they are not None
                current_seller_income = Decimal(existing_commission[0]) if existing_commission[0] is not None else Decimal('0')
                current_admin_income = Decimal(existing_commission[1]) if existing_commission[1] is not None else Decimal('0')

                # Calculate new values
                new_seller_income = current_seller_income + seller_income
                new_admin_income = current_admin_income + admin_commission

                # Update admin commission table with the new values
                query_update_commission = """
                    UPDATE admin_commission
                    SET seller_income = %s, admin_income = %s
                    WHERE seller_id = %s
                """
                cursor.execute(query_update_commission, (new_seller_income, new_admin_income, seller_id))
            else:
                # Insert a new record if no existing commission found
                query_insert_commission = """
                    INSERT INTO admin_commission (seller_id, seller_income, admin_income)
                    VALUES (%s, %s, %s)
                """
                cursor.execute(query_insert_commission, (seller_id, seller_income, admin_commission))

        # Get order items to update stocks
        query_get_order_items = """
            SELECT productid, productqty
            FROM order_items
            WHERE order_id = %s
        """
        cursor.execute(query_get_order_items, (order_id,))
        order_items = cursor.fetchall()

        # Aggregate product quantities for the seller
        total_qty_sold = sum(item[1] for item in order_items)

        # Update sales table: sold_products and total_income (after admin commission)
        query_check_sales = """
            SELECT sold_products_qty, total_income
            FROM sales
            WHERE seller_id = %s
        """
        cursor.execute(query_check_sales, (seller_id,))
        existing_sales = cursor.fetchone()

        if existing_sales:
            current_sold_products = existing_sales[0] if existing_sales[0] is not None else 0
            current_total_income = existing_sales[1] if existing_sales[1] is not None else Decimal('0')

            new_sold_products = current_sold_products + total_qty_sold
            new_total_income = current_total_income + seller_income  # seller_income already subtracts the 10%

            query_update_sales = """
                UPDATE sales
                SET sold_products_qty = %s, total_income = %s
                WHERE seller_id = %s
            """
            cursor.execute(query_update_sales, (new_sold_products, new_total_income, seller_id))
        else:
            query_insert_sales = """
                INSERT INTO sales (seller_id, sold_products_qty, total_income)
                VALUES (%s, %s, %s)
            """
            cursor.execute(query_insert_sales, (seller_id, total_qty_sold, seller_income))  # Insert seller_income

        for item in order_items:
            product_id = item[0]
            product_qty = item[1]

            query_update_stock = """
                UPDATE products
                SET productstocks = productstocks - %s
                WHERE productid = %s
            """
            cursor.execute(query_update_stock, (product_qty, product_id))

        # Insert notification for the seller
        notification_message = "An order has been marked as received."
        notification_link = "/orders"
        query_insert_notification = """
            INSERT INTO seller_notif (seller_id, message, link, created_at)
            VALUES (%s, %s, %s, NOW())
        """
        cursor.execute(query_insert_notification, (seller_id, notification_message, notification_link))

        connection.commit()

        return jsonify({"success": True, "message": "Order marked as received."})

    except Exception as e:
        connection.rollback()
        return jsonify({"success": False, "message": str(e)}), 500

    finally:
        cursor.close()
        connection.close()

@app.route('/api/courier_info', methods=['GET'])
def get_courier_info():
    courier_id = request.args.get('courier_id')
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT first_name, last_name FROM courier_info WHERE courier_id = %s", (courier_id,))
    courier = cursor.fetchone()

    cursor.close()
    conn.close()

    if courier:
        # Concatenate the full name (you can adjust formatting as needed)
        full_name = f"{courier['first_name']} {courier['last_name']}".strip()
        return jsonify({"status": "success", "name": full_name})
    else:
        return jsonify({"status": "error", "message": "Courier not found"}), 404

@app.route('/update_pickup_status', methods=['POST'])
def update_pickup_status():
    try:
        data = request.get_json()
        order_id = data['order_id']
        new_status = data['status']
        courier_id = data['courier_id']  # Get courier_id from request

        conn = get_db_connection()
        cursor = conn.cursor()

        # Update the status and courier_id in for_pickup table
        update_for_pickup_query = """
            UPDATE for_pickup 
            SET status = %s, courier_id = %s
            WHERE order_id = %s
        """
        cursor.execute(update_for_pickup_query, (new_status, courier_id, order_id))
        conn.commit()

        # Update the status and shipped_date in orders table
        update_orders_query = """
            UPDATE orders 
            SET status = %s, shipped_date = NOW()
            WHERE order_id = %s
        """
        cursor.execute(update_orders_query, (new_status, order_id))
        conn.commit()

        # Fetch user_id from orders table based on order_id
        fetch_user_query = "SELECT user_id FROM orders WHERE order_id = %s"
        cursor.execute(fetch_user_query, (order_id,))
        res = cursor.fetchone()

        if res:  # Ensure the order exists
            user_id = res[0]
            print(f"User ID for Order {order_id}: {user_id}")

            # Insert notification for the buyer
            notification_message = "Your order has been shipped!"
            notification_link = "/my_orders"
            insert_notification_query = """
                INSERT INTO buyer_notif (user_id, message, link, is_read, created_at)
                VALUES (%s, %s, %s, 0, NOW())
            """
            cursor.execute(insert_notification_query, (user_id, notification_message, notification_link))
            conn.commit()
            print("Notification inserted successfully")
        else:
            print(f"No user found for order_id: {order_id}")

        cursor.close()
        conn.close()

        return jsonify({"success": True, "message": "Status updated successfully"})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"success": False, "error": str(e)})


@app.route('/api/for_pickup/picked_up', methods=['GET'])
def picked_up_orders():
    try:
        # Get courier_id from request parameters
        courier_id = request.args.get('courier_id')
        if not courier_id:
            return jsonify({'status': 'error', 'message': 'Courier ID is required'}), 400
            
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        query = """
        SELECT 
            order_id, buyer, buyer_address, phonenumber 
        FROM 
            for_pickup 
        WHERE 
            status = 'Picked up' AND courier_id = %s
        """

        cursor.execute(query, (courier_id,))
        orders = cursor.fetchall()
        cursor.close()
        connection.close()

        return jsonify({'status': 'success', 'orders': orders}), 200

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500


@app.route('/api/for_pickup/delivered', methods=['GET'])
def delivered_orders():
    try:
        # Get courier_id from request parameters
        courier_id = request.args.get('courier_id')
        if not courier_id:
            return jsonify({'status': 'error', 'message': 'Courier ID is required'}), 400
            
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        query = """
        SELECT 
            order_id,
            buyer,
            buyer_address,
            phonenumber
        FROM 
            for_pickup
        WHERE 
            status = 'Delivered' AND courier_id = %s
        """

        cursor.execute(query, (courier_id,))
        orders = cursor.fetchall()
        cursor.close()
        connection.close()

        return jsonify({'status': 'success', 'orders': orders}), 200

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500


# @app.route('/api/for_pickup/mark_received', methods=['POST'])
# def mark_order_received():
#     try:
#         # Get order_id from request JSON body
#         data = request.get_json()
        
#         if not data or 'order_id' not in data:
#             return jsonify({'status': 'error', 'message': 'Order ID is required'}), 400
        
#         order_id = data['order_id']
        
#         # Get database connection
#         connection = get_db_connection()
#         cursor = connection.cursor(dictionary=True)
        
#         # Update the order status to 'Received' and set received_date to current datetime
#         update_query = """
#         UPDATE for_pickup
#         SET status = 'Delivered',
#             received_date = NOW()
#         WHERE order_id = %s
#         """
        
#         cursor.execute(update_query, (order_id,))
        
#         # Commit the transaction
#         connection.commit()
        
#         # Close cursor and connection
#         cursor.close()
#         connection.close()
        
#         return jsonify({'status': 'success', 'message': f'Order {order_id} marked as received'}), 200

#     except Exception as e:
#         print(f"Error updating order status: {e}")
#         return jsonify({'status': 'error', 'message': str(e)}), 500


@app.route('/api/for_pickup/mark_received', methods=['POST'])
def mark_order_received():
    try:
        # Get order_id from request JSON body
        data = request.get_json()
        
        if not data or 'order_id' not in data:
            return jsonify({'status': 'error', 'message': 'Order ID is required'}), 400
        
        order_id = data['order_id']
        
        # Get database connection
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        
        # Update the for_pickup table status to 'Delivered' and set received_date to current datetime
        update_pickup_query = """
        UPDATE for_pickup
        SET status = 'Delivered',
            received_date = NOW()
        WHERE order_id = %s
        """
        
        cursor.execute(update_pickup_query, (order_id,))
        
        # Also update the orders table with status 'Received'
        update_orders_query = """
        UPDATE orders
        SET status = 'Received'
        WHERE order_id = %s
        """
        
        cursor.execute(update_orders_query, (order_id,))
        
        # Commit the transaction
        connection.commit()
        
        # Close cursor and connection
        cursor.close()
        connection.close()
        
        return jsonify({'status': 'success', 'message': f'Order {order_id} marked as received'}), 200

    except Exception as e:
        print(f"Error updating order status: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

