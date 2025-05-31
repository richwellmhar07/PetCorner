from flask import Flask, render_template, request, redirect, url_for, session, flash, json, jsonify
import mysql.connector
import os
from werkzeug.utils import secure_filename
import random
from flask_mail import Mail, Message
from datetime import datetime
import base64
from flask import send_file
from io import BytesIO
from decimal import Decimal


app = Flask(__name__)
app.secret_key = 'your_secret_key'

def generate_verification_code():
    return str(random.randint(100000, 999999)) 

app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 465
app.config['MAIL_USE_SSL'] = True
app.config['MAIL_USERNAME'] = 'petcorner999@gmail.com'  
app.config['MAIL_PASSWORD'] = 'znvo uect zpsa wtmv'  
app.config['MAIL_DEBUG'] = True 

mail = Mail(app)

def get_db_connection():
    conn = mysql.connector.connect(
        host='localhost',
        user='root',
        password='',
        database='petcorner'
    )
    return conn
############################################################ Function for verifiying email address

@app.route('/set_user_info', methods=['POST'])
def set_user_info():
    user_info = request.get_json()
    session['user_info'] = json.dumps(user_info)  
    return '', 200 

@app.route('/send_verification_code', methods=['POST'])
def send_verification_code():
    email = request.form['email']
    
    if not email:
        flash('Please provide a valid email address.', 'danger')
        return redirect(url_for('signup')) 

    verification_code = generate_verification_code()

    
    session['verification_code'] = verification_code
    session['email'] = email  
  
    try:
        msg = Message("Your Verification Code", sender=app.config['MAIL_USERNAME'], recipients=[email])
        msg.body = f"Your verification code is: {verification_code}"
        mail.send(msg)
       # flash('A verification code has been sent to your email.', 'success')
    except Exception as e:
        flash(f'Failed to send verification code. Error: {str(e)}', 'danger')
        return redirect(url_for('signup'))

    return redirect(url_for('signup')) 


@app.route('/check_email_existence', methods=['POST'])
def check_email_existence():
    email = request.form['email']

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Check if the email exists in buyer_information
        cursor.execute("SELECT email FROM buyer_information WHERE email = %s", (email,))
        buyer_email = cursor.fetchone()

        # Check if the email exists in seller_information
        cursor.execute("SELECT email FROM seller_information WHERE email = %s", (email,))
        seller_email = cursor.fetchone()

        if buyer_email or seller_email:
            return jsonify({'exists': True})
        else:
            return jsonify({'exists': False})

    except Exception as e:
        return jsonify({'error': str(e)})

    finally:
        cursor.close()
        conn.close()

####################################################################### Checking product quantity in cart

@app.route('/verify_code', methods=['POST'])
def verify_code():
    entered_code = request.form['verificationCode']
    stored_code = session.get('verification_code')

    if not stored_code:
        flash('No verification code found. Please request a new one.', 'danger')
        return redirect(url_for('signup'))



    if entered_code == stored_code:

        user_info = json.loads(session.get('user_info', '{}'))

        username = user_info.get('username')
        password = user_info.get('password')
        email = user_info.get('email')
        user_type = user_info.get('user_type')

        session['username'] = username  
        session['password'] = password  
        session['email'] = email       

        conn = get_db_connection()
        cursor = conn.cursor()

        try:

            cursor.execute(
                "SELECT email FROM buyer_information WHERE email = %s", (email,)
            )
            buyer_email = cursor.fetchone()

            cursor.execute(
                "SELECT email FROM seller_information WHERE email = %s", (email,)
            )
            seller_email = cursor.fetchone()

            if buyer_email or seller_email:
                flash('This email address is already registered.', 'danger')
                return redirect(url_for('signup'))

            if user_type == 'buyer':
           
                sql = "INSERT INTO buyer_information (username, password, email) VALUES (%s, %s, %s)"
                values = (username, password, email)

            elif user_type == 'seller':
                return redirect(url_for('sellerregistration'))
            
            else:
                flash('Invalid user type!', 'danger')
                return redirect(url_for('signup'))

            cursor.execute(sql, values)
            conn.commit()

            flash('Account created successfully!', 'success')
            return redirect(url_for('login'))

        except Exception as e:
            conn.rollback()
            flash(f'There was an error with the database insertion: {e}', 'danger')

        finally:
            cursor.close()
            conn.close()

    else:
        flash('Incorrect verification code. Please try again.', 'danger')
        return redirect(url_for('signup'))


################################################################# Function for loading products in the buyer's view

@app.route('/show_products')
def show_products():
    category = request.args.get('category')  # Get the category filter from query params
    search_query = request.args.get('search', '').strip()  # Get the search query from URL params
    
    conn = get_db_connection()
    cursor = conn.cursor()

    user_id = session.get('user_id')

    # Base query to fetch products
    query = """
        SELECT p.productid, p.productname, p.productimage, p.productprice, p.productstocks, product_quality, feedback,
               p.productdescription, s.shopname, s.seller_id
        FROM products p
        JOIN seller_information s ON p.seller_id = s.seller_id
        WHERE 1=1
    """
    params = []

    # Add search query filter (if any)
    if search_query:
        query += " AND (p.productname LIKE %s OR p.productdescription LIKE %s)"
        params.extend([f"%{search_query}%", f"%{search_query}%"])

    # If a category filter is provided, add it to the query
    if category:
        query += " AND p.productcategory = %s"
        params.append(category)
    
    cursor.execute(query, tuple(params))

    products = cursor.fetchall()

    products = [
        (
            str(product[0]),  # productid
            product[1],  # productname
            str(product[2]),  # productimage
            product[3],  # productprice
            product[4],  # productstocks (not used in the template now)
            product[5],  # product_quality
            product[6],  # feedback
            product[7],  # productdescription
            product[8],  # shopname
            product[9],  # seller_id
            # Calculate product rating, treat None as 0 to avoid division errors
            (product[5] / product[6] if product[5] is not None and product[6] is not None and product[6] != 0 else 0)
        ) for product in products
    ]

    # Fetch notifications for the logged-in user
    query_notifications = """
        SELECT message, link, created_at 
        FROM buyer_notif 
        WHERE user_id = %s 
        ORDER BY created_at DESC
    """
    cursor.execute(query_notifications, (user_id,))
    notifications = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('index.html', products=products, search_query=search_query, category=category, notifications=notifications)

################################################################ Function for login
@app.route('/')
def login():
    return render_template('login.html')

@app.route('/signup')
def signup():
    return render_template('signup.html')

@app.route('/login', methods=['POST'])
def login_user():
    username_or_email = request.form['username']
    password = request.form['password']

    conn = get_db_connection()
    cursor = conn.cursor()

    sql_buyer = """
        SELECT user_id, 'buyer' AS role FROM buyer_information 
        WHERE (username = %s OR email = %s) AND password = %s
    """
    cursor.execute(sql_buyer, (username_or_email, username_or_email, password))
    buyer = cursor.fetchone()

    sql_seller = """
        SELECT seller_id, 'seller' AS role FROM seller_information 
        WHERE (username = %s OR email = %s) AND password = %s
    """
    cursor.execute(sql_seller, (username_or_email, username_or_email, password))
    seller = cursor.fetchone()

    sql_admin = """
        SELECT admin_id, 'admin' AS role FROM admin_information 
        WHERE (username = %s OR email = %s) AND password = %s
    """
    cursor.execute(sql_admin, (username_or_email, username_or_email, password))
    admin = cursor.fetchone()

    sql_courier = """
        SELECT courier_id, 'courier' AS role FROM courier_information 
        WHERE (username = %s OR email = %s) AND password = %s
    """
    cursor.execute(sql_courier, (username_or_email, username_or_email, password))
    courier = cursor.fetchone()

    cursor.close()
    conn.close()

    if buyer:
        session['user_id'] = buyer[0]  
        session['role'] = buyer[1] 
        return redirect(url_for('show_products'))
    elif seller:
        session['seller_id'] = seller[0] 
        session['role'] = seller[1]  
        return redirect(url_for('seller'))
    elif admin:
        session['admin_id'] = admin[0] 
        session['role'] = admin[1]  
        return redirect(url_for('sales'))
    elif courier:
        session['courier_id'] = courier[0] 
        session['role'] = courier[1]  
        return redirect(url_for('courierdb'))
    else:
        flash('Incorrect username or password. Please try again.', 'danger')
        return redirect(url_for('login'))

##########################################  logout function

@app.route('/logout', methods=['POST', 'GET'])
def logout():
    session.clear()  
    return redirect(url_for('login'))  


# ################################################### Function for Displaying the Products in the table

@app.route('/seller')
def seller():
    seller_id = session.get('seller_id')
    if not seller_id:
        return redirect(url_for('login'))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Query to fetch product data for the seller
    cursor.execute("""
        SELECT productid, productname, productdescription, productcategory, productprice, productstocks, productimage
        FROM products 
        WHERE seller_id = %s
    """, (seller_id,))
    products = cursor.fetchall()

    cursor.execute("""
        SELECT message, link, created_at 
        FROM seller_notif 
        WHERE seller_id = %s 
        ORDER BY created_at DESC
    """, (seller_id,))
    notifications = cursor.fetchall()  # Notifications as dictionaries


    # Query to fetch sold_products_qty, total_income, and shop_ratings from sales table
    cursor.execute("""
        SELECT sold_products_qty, total_income, seller_service, delivery_speed, feedback
        FROM sales
        WHERE seller_id = %s
    """, (seller_id,))
    sales_data = cursor.fetchone()

    sold_products_qty = 0
    total_income = 0
    shop_ratings = 0

    if sales_data:
        sold_products_qty = sales_data.get('sold_products_qty', 0) or 0
        total_income = sales_data.get('total_income', 0) or 0
        seller_service = sales_data.get('seller_service', 0)
        delivery_speed = sales_data.get('delivery_speed', 0)
        feedback = sales_data.get('feedback', 0)

        if feedback > 0:
            result1 = seller_service / feedback
            result2 = delivery_speed / feedback
            shop_ratings = (result1 + result2) / 2  
            shop_ratings = round(shop_ratings, 1)

    cursor.close()
    conn.close()

    return render_template('seller.html', products=products, notifications=notifications, sold_products_qty=sold_products_qty, total_income=total_income, shop_ratings=shop_ratings)

##################################################### Function for seller registration
@app.route('/sellerregistration')
def sellerregistration():
    return render_template('sellerinformation.html')

ALLOWED_IMAGE_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

def allowed_file(filename, allowed_extensions):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed_extensions


@app.route('/register_seller', methods=['POST'])
def register_seller():
    lastname = request.form['lastname']
    firstname = request.form['firstname']
    middlename = request.form['middlename'] 
    birthday = request.form['birthday']
    gender = request.form['gender']
    province = request.form['province']
    municipality = request.form['municipality']
    barangay = request.form['barangay']
    postalCode = request.form['postalCode']
    contact = request.form['contact']
    shopname = request.form['shopname']
    idtype = request.form['idtype']

    username = session.get('username')
    password = session.get('password') 
    email = session.get('email')

    if not username or not password or not email:
        flash('Missing required credentials (username, password, or email). Please complete the signup process.', 'danger')
        return redirect(url_for('signup'))

    # Handling image file (ID upload)
    uploadedid = request.files['uploadedid']
    businesspermit = request.files['businesspermit']

    # Validate business permit file
    if 'businesspermit' not in request.files or businesspermit.filename == '':
        flash('No business permit file uploaded.', 'danger')
        return redirect(url_for('sellerregistration'))

    # Check if the business permit file is an allowed image type
    if not allowed_file(businesspermit.filename, ALLOWED_IMAGE_EXTENSIONS):
        flash('Invalid file type for business permit. Please upload an image file (png, jpg, jpeg, gif).', 'danger')
        return redirect(url_for('sellerregistration'))

    # Read and save uploaded files (business permit and ID)
    uploadedid_data = uploadedid.read()
    businesspermit_data = businesspermit.read()

    # Save the business permit file to the server (optional)
    # businesspermit_filename = secure_filename(businesspermit.filename)
    # businesspermit.save(os.path.join('uploads/businesspermits', businesspermit_filename))
    # flash('Business permit uploaded successfully!', 'success')

    # Connect to the database
    conn = get_db_connection()
    cursor = conn.cursor()

    # Insert data into the `seller_application` table
    insert_seller_query = """
        INSERT INTO seller_application (
            username, password, email, lastname, firstname, middlename, birthday, 
            gender, province, municipality, barangay, postalCode, contact, shopname, idtype, uploadedid, businesspermit, submission_date
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
    """

    seller_values = (
        username, password, email, lastname, firstname, middlename, birthday, 
        gender, province, municipality, barangay, postalCode, contact, shopname, idtype, uploadedid_data, businesspermit_data
    )

    # Notification data
    notification_message = f"New seller wants to apply! {firstname} {lastname}"
    notification_link = url_for('new_seller')  # Adjust as needed
    insert_notification_query = """
        INSERT INTO notifications (message, link, is_read)
        VALUES (%s, %s, %s)
    """

    try:
        # Execute both insertions
        cursor.execute(insert_seller_query, seller_values)
        cursor.execute(insert_notification_query, (notification_message, notification_link, False))
        conn.commit()
        flash('Application submitted successfully! Wait for admin approval.', 'success')
    except mysql.connector.Error as db_error:
        conn.rollback() 
        flash(f'There was an error registering the seller: {db_error}', 'danger')
        print(f"Database error: {db_error}")
    except Exception as e:
        conn.rollback()  
        flash(f'There was an unexpected error: {e}', 'danger')
        print(f"Unexpected error: {e}")
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('login'))


############################################################## Function for Add products in seller page

UPLOAD_FOLDER = 'static/images'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route('/add_product', methods=['POST'])
def add_product():
    # Check if seller is logged in
    if 'seller_id' not in session:
        flash('Please log in to add a product.', 'danger')
        return redirect(url_for('login'))

    # Get the seller_id from the session
    seller_id = session['seller_id']
    
    if request.method == 'POST':
        # Get form data
        productname = request.form['productname']
        productdescription = request.form['productdescription']
        productcategory = request.form['productcategory']
        productprice = request.form['productprice']
        productstocks = request.form['productstocks']
        
        # Save the uploaded image
        productimage = request.files['productimage']
        filename = secure_filename(productimage.filename)
        productimage.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))

        conn = get_db_connection()
        cursor = conn.cursor()
        # Insert product data along with seller_id
        cursor.execute(
            "INSERT INTO products (productname, productdescription, productcategory, productprice, productstocks, productimage, seller_id) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (productname, productdescription, productcategory, productprice, productstocks, filename, seller_id)
        )
        conn.commit()
        cursor.close()
        conn.close()

        flash('New product added successfully.', 'success')
        return redirect(url_for('seller'))

############################################################# Function for Updating products in seller page

@app.route('/update_products/<int:productid>', methods=['POST'])  
def update_products(productid):
    # Get form data
    productname = request.form['productname']
    productdescription = request.form['productdescription']
    productcategory = request.form['productcategory']
    productprice = request.form['productprice']
    productstocks = request.form['productstocks']
    productimage = request.files['productimage']

    conn = get_db_connection()
    cursor = conn.cursor()

    if productimage.filename != '':
    
        filename = secure_filename(productimage.filename)
        productimage.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
       
        cursor.execute("""
            UPDATE products 
            SET productname = %s, productdescription = %s, productcategory = %s, productprice = %s, productstocks = %s, productimage = %s 
            WHERE productid = %s
            """, 
            (productname, productdescription, productcategory, productprice, productstocks, filename, productid)
        )
    else:
     
        cursor.execute("""
            UPDATE products 
            SET productname = %s, productdescription = %s, productcategory = %s, productprice = %s, productstocks = %s
            WHERE productid = %s
            """, 
            (productname, productdescription, productcategory, productprice, productstocks, productid)
        )

    conn.commit()
    cursor.close()
    conn.close()

    flash('Product updated successfully!', 'success')
    return redirect(url_for('seller'))

########################################################### Function for archiving products in seller page

@app.route('/archive_product/<int:productid>', methods=['POST'])  
def archive_product(productid):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM products WHERE productid = %s", (productid,))
    product = cursor.fetchone()

    if product:
       
        cursor.execute("""
            INSERT INTO productarchive (productid, productname, productdescription, productcategory, productprice, productstocks, productimage)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            product[0],  # productid
            product[1],  # productname
            product[2],  # productdescription
            product[3],  # productcategory
            product[4],  # productprice
            product[5],  # productstocks
            product[6]   # productimage
        ))

        # Delete product from products table
        cursor.execute("DELETE FROM products WHERE productid = %s", (productid,))
        conn.commit()

        flash('Product archived successfully.', 'success')
    else:
        flash('Product not found.', 'error')

    cursor.close()
    conn.close()

    return redirect(url_for('seller'))

######################################################### Function for Displaying Sellers info in admin page

@app.route('/admin')
def admin():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT seller_id, CONCAT_WS(' ', lastname, firstname, middlename) AS name, CONCAT_WS(' ', province, municipality, barangay) AS address, contact, email, shopname FROM seller_information")
    sellers = cursor.fetchall()

    cursor.execute('SELECT message, link FROM notifications WHERE is_read = FALSE ORDER BY created_at DESC')
    notifications = cursor.fetchall()

    notifications_data = [{'message': notification[0], 'link': notification[1]} for notification in notifications]

    cursor.close()
    conn.close()
    return render_template('admin.html', sellers=sellers, notifications=notifications_data)


####### For New Seller Page

@app.route('/new seller')
def new_seller():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("""
            SELECT seller_no, CONCAT(lastname, ' ', firstname) AS name, email, shopname, submission_date 
            FROM seller_application
            ORDER BY submission_date DESC
        """)
    sellers = cursor.fetchall()

    cursor.execute('SELECT message, link FROM notifications WHERE is_read = FALSE ORDER BY created_at DESC')
    notifications = cursor.fetchall()

    notifications_data = [{'message': notification[0], 'link': notification[1]} for notification in notifications]

    conn.close()
    return render_template('sellerapplication.html', sellers=sellers, notifications=notifications_data)



################################################################# Function for user account

@app.route('/account')
def account():
    if 'user_id' not in session:
        flash('You are not logged in!', 'danger')
        return redirect(url_for('login'))

    user_id = session['user_id']
    role = session['role'] 

    conn = get_db_connection()
    cursor = conn.cursor()

    if role == 'buyer':
        sql = """
            SELECT user_id, name, username, email, password, phonenumber, birthday, gender, address, profile 
            FROM buyer_information 
            WHERE user_id = %s
        """
    cursor.execute(sql, (user_id,))
    user_info = cursor.fetchone()
    
    # Fetch notifications for the logged-in user
    query_notifications = """
        SELECT message, link, created_at 
        FROM buyer_notif 
        WHERE user_id = %s 
        ORDER BY created_at DESC
    """
    cursor.execute(query_notifications, (user_id,))
    notifications = cursor.fetchall()

    cursor.close()
    conn.close()

    if not user_info:
        flash('User not found!', 'danger')
        return redirect(url_for('login'))

    
    profile_image = None
    if user_info[9]:  
        print("Raw BLOB data present.")
        try:
            profile_blob = bytes(user_info[9]) if not isinstance(user_info[9], bytes) else user_info[9]
            profile_image = base64.b64encode(profile_blob).decode('utf-8')
            print("Profile Image Base64:", profile_image)  
        except Exception as e:
            print("Error converting profile to bytes:", e)

  
    return render_template('account.html', user_info=user_info, profile_image=profile_image, role=role, notifications=notifications)

################################################################# Function for seller account

@app.route('/accountseller')
def accountseller():
    if 'seller_id' not in session:
        flash('You are not logged in!', 'danger')
        return redirect(url_for('login'))

    seller_id = session['seller_id']
    role = session.get('role')

    conn = get_db_connection()
    cursor = conn.cursor()

    if role == 'seller':
        sql = """
            SELECT seller_id, shopname, lastname, firstname, middlename, username, email, password, contact, birthday, gender, province, municipality, barangay, profile 
            FROM seller_information 
            WHERE seller_id = %s
        """
        cursor.execute(sql, (seller_id,))
        seller_info = cursor.fetchone()
        
        if not seller_info:
            flash('User not found!', 'danger')
            return redirect(url_for('login'))
    else:
        flash('Invalid role!', 'danger')
        return redirect(url_for('login'))
    
    cursor.execute("""
        SELECT message, link, created_at 
        FROM seller_notif 
        WHERE seller_id = %s 
        ORDER BY created_at DESC
    """, (seller_id,))

    notifications = cursor.fetchall()  # Notifications as dictionaries

    cursor.close()
    conn.close()

    # Convert the profile image (BLOB) to base64 if present
    profile_image = None
    if seller_info and seller_info[12]: 
        try:
            profile_blob = bytes(seller_info[12]) if not isinstance(seller_info[12], bytes) else seller_info[12]
            profile_image = base64.b64encode(profile_blob).decode('utf-8')
        except Exception as e:
            print("Error converting profile to bytes:", e)

    return render_template('accountseller.html', seller_info=seller_info, profile_image=profile_image, role=role, notifications=notifications)

################################################################## Function Changing qty in the cart

@app.route('/update_cart_quantity', methods=['POST'])
def update_cart_quantity():
    data = request.get_json()
    cartid = data.get('cartid')
    quantity = int(data.get('quantity'))

    if not cartid or quantity is None:
        return jsonify({'success': False, 'error': 'Invalid cart ID or quantity'})

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Get the product ID from the cart
        cursor.execute("SELECT productid FROM cart WHERE cartid = %s", (cartid,))
        product = cursor.fetchone()
        if not product:
            return jsonify({'success': False, 'error': 'Product not found in cart'})

        product_id = product[0]

        # Get the available stock from the products table
        cursor.execute("SELECT productstocks FROM products WHERE productid = %s", (product_id,))
        stock = cursor.fetchone()
        if not stock:
            return jsonify({'success': False, 'error': 'Stock information unavailable'})

        available_stock = stock[0]

        # Ensure requested quantity does not exceed available stock
        if quantity > available_stock:
            return jsonify({'success': False, 'error': 'Requested quantity exceeds available stock', 'max_stock': available_stock})

        # Update the quantity in the database
        cursor.execute("""
            UPDATE cart
            SET productqty = %s
            WHERE cartid = %s
        """, (quantity, cartid))
        conn.commit()
        return jsonify({'success': True, 'updated_quantity': quantity})
    
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'error': str(e)})
    
    finally:
        cursor.close()
        conn.close()


################################################################# Function for loading buyer's cart

@app.route('/cart')
def cart():
    if 'user_id' not in session:
        flash('You need to log in to view your cart.', 'danger')
        return redirect(url_for('login'))

    user_id = session['user_id']

    conn = get_db_connection()
    cursor = conn.cursor()

    # Fetch cart items for the logged-in user
    cursor.execute("""
        SELECT cartid, productid, productname, productimage, productprice, productqty, shopname, seller_id
        FROM cart D
        WHERE user_id = %s
        ORDER BY cartid DESC
    """, (user_id,))
    cart_items = cursor.fetchall()

    # Fetch notifications for the logged-in user
    cursor.execute("""
        SELECT message, link, created_at 
        FROM buyer_notif 
        WHERE user_id = %s 
        ORDER BY created_at DESC
    """, (user_id,))
    notifications = cursor.fetchall()

    cursor.close()
    conn.close()

    # Calculate subtotal
    subtotal = sum(item[4] * item[5] for item in cart_items) 
    return render_template('cart.html', cart_items=cart_items, subtotal=subtotal, notifications=notifications)

################################################################# Add to cart function

@app.route('/add_to_cart', methods=['POST'])
def add_to_cart():
    # Ensure the user is logged in and get the user_id from the session
    if 'user_id' not in session:
        return jsonify({'error': 'User not logged in'}), 401

    user_id = session['user_id']

    # Retrieve product details from the request
    product_id = request.form['product_id']
    product_name = request.form['product_name']
    product_price = request.form['product_price']
    product_qty = int(request.form['product_qty'])  # Ensure quantity is an integer
    product_image = request.form['product_image']
    shop_name = request.form['shop_name']
    seller_id = request.form['seller_id']  # Retrieve seller_id

    conn = get_db_connection()
    cursor = conn.cursor()

    # Get available stock for the product
    cursor.execute(
        "SELECT productstocks FROM products WHERE productid = %s",
        (product_id,)
    )
    stock_result = cursor.fetchone()

    if not stock_result:
        return jsonify({'error': 'Product not found'}), 404

    available_stock = stock_result[0]  # Available stock in the database

    # Check if the product already exists in the cart
    cursor.execute(
        "SELECT productqty FROM cart WHERE user_id = %s AND productid = %s",
        (user_id, product_id)
    )
    existing_product = cursor.fetchone()

    if existing_product:
        # Calculate new quantity after adding the requested amount
        new_quantity = existing_product[0] + product_qty

        # Check if new quantity exceeds available stock
        if new_quantity > available_stock:
            return jsonify({'error': 'Cannot add more than available stock', 'max_stock': available_stock})

        # Update existing quantity in cart
        cursor.execute(
            """
            UPDATE cart 
            SET productqty = %s 
            WHERE user_id = %s AND productid = %s
            """,
            (new_quantity, user_id, product_id)
        )
        message = 'Product quantity updated successfully'
    else:
        # Ensure requested quantity does not exceed available stock
        if product_qty > available_stock:
            return jsonify({'error': 'Cannot add more than available stock', 'max_stock': available_stock})

        # Insert new product into cart
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

    return jsonify({'message': message})

################################################################## Function for deleting products to cart

@app.route('/delete_cart_item', methods=['POST'])
def delete_cart_item():
    data = request.get_json()
    cartid = data.get('cartid')

    if not cartid:
        return jsonify({'success': False, 'error': 'Invalid cart ID'}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Execute deletion query with parameterized query
        cursor.execute("DELETE FROM cart WHERE cartid = %s", (cartid,))
        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({'success': True})
    except Exception as e:
        print(f"Error deleting item: {e}")  # For debugging
        return jsonify({'success': False, 'error': 'Database error'}), 500


################################################################## Function Update Account For Buyers




################################################################## Function for Notification

@app.route('/notification')
def notification():
    return render_template('notification.html')

################################################################## Function for Displaying Buyer's info in Admin page

@app.route('/buyer_info')
def display_buyer_info():
    connection = get_db_connection()
    cursor = connection.cursor()

    # Fetch the necessary columns from 'buyer_information'
    query = "SELECT user_id, name, address, email, phonenumber, username FROM buyer_information"
    cursor.execute(query)
    buyers = cursor.fetchall()

    cursor.execute('SELECT message, link FROM notifications WHERE is_read = FALSE ORDER BY created_at DESC')
    notifications = cursor.fetchall()

    notifications_data = [{'message': notification[0], 'link': notification[1]} for notification in notifications]

    cursor.close()
    connection.close()

    # Pass the data to the correct template
    return render_template('admin-buyers.html', buyers=buyers, notifications=notifications_data)

################################################################## Function for Displaying Products info in Admin page

@app.route('/product_info')
def display_product_info():
    connection = get_db_connection()
    cursor = connection.cursor()

    # Fetch the necessary columns from 'buyer_information'
    query = "SELECT productid, productname, productdescription, productcategory, productprice, productstocks, productimage FROM products"
    cursor.execute(query)
    products = cursor.fetchall()

    cursor.execute('SELECT message, link FROM notifications WHERE is_read = FALSE ORDER BY created_at DESC')
    notifications = cursor.fetchall()

    notifications_data = [{'message': notification[0], 'link': notification[1]} for notification in notifications]

    cursor.close()
    connection.close()

    # Pass the data to the correct template
    return render_template('admin-products.html', products=products, notifications=notifications_data)

################################################################### View seller application details 

@app.route('/get_seller_details/<int:seller_no>', methods=['GET'])
def get_seller_details(seller_no):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Query to fetch seller details, including ID and business permit
        cursor.execute("""
            SELECT seller_no, lastname, firstname, middlename, birthday, gender, province, municipality, barangay, email, contact, shopname, username, password, uploadedid, businesspermit
            FROM seller_application
            WHERE seller_no = %s
        """, (seller_no,))

        seller = cursor.fetchone()
        conn.close()

        if seller:
            if seller[4]:
                birthday = seller[4].strftime('%d %b %Y')  # Format date as '19 Aug 1995'
            else:
                birthday = None  # Handle case if birthday is None

            # Convert BLOB data to base64 for displaying as images
            uploadedid_base64 = base64.b64encode(seller[14]).decode('utf-8') if seller[14] else None
            businesspermit_base64 = base64.b64encode(seller[15]).decode('utf-8') if seller[15] else None

            # Prepare and return seller data as JSON response
            seller_data = {
                'seller_no': seller[0],
                'name': f"{seller[1]} {seller[2]} {seller[3]}",  # Full name
                'address': f"{seller[6]} {seller[7]} {seller[8]}",
                'birthday': birthday,
                'gender': seller[5],
                'email': seller[9],
                'contact': seller[10],
                'shopname': seller[11],
                'username': seller[12],
                'password': seller[13],
                'uploadedid': uploadedid_base64,
                'businesspermit': businesspermit_base64
            }
            return jsonify(seller_data)
        else:
            return jsonify({'error': 'Seller not found'}), 404

    except Exception as e:
        return jsonify({'error': f"An error occurred: {str(e)}"}), 500

#################### download id

@app.route('/download_id/<int:seller_no>')
def download_id(seller_no):
    try:
        # Fetch the ID picture (BLOB) from the database
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT uploadedid FROM seller_application WHERE seller_no = %s", (seller_no,))
        id_picture = cursor.fetchone()
        conn.close()

        # Return the image file for download
        if id_picture:
            return send_file(BytesIO(id_picture[0]), mimetype='image/jpeg', as_attachment=True, download_name='id_picture.jpg')
        else:
            return jsonify({'error': 'ID picture not found'}), 404

    except Exception as e:
        return jsonify({'error': f"An error occurred: {str(e)}"}), 500
    
#########################################################################################3

@app.route('/download_pdf/<int:seller_no>')
def download_pdf(seller_no):
    try:
        # Fetch the Business Permit PDF (BLOB) from the database
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT businesspermit FROM seller_application WHERE seller_no = %s", (seller_no,))
        pdf_file = cursor.fetchone()
        conn.close()

        # Return the PDF file for download
        if pdf_file:
            return send_file(BytesIO(pdf_file[0]), mimetype='application/pdf', as_attachment=True, download_name='business_permit.pdf')
        else:
            return jsonify({'error': 'Business permit not found'}), 404

    except Exception as e:
        return jsonify({'error': f"An error occurred: {str(e)}"}), 500
    
################################################################################################# Approve function

@app.route('/approve_seller/<int:seller_no>', methods=['POST'])
def approve_seller(seller_no):
    # Connect to the database
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Fetch seller details from the seller_application table
        cursor.execute("""
            SELECT lastname, firstname, middlename, birthday, gender, province, municipality, barangay, email, contact, shopname, username, password
            FROM seller_application
            WHERE seller_no = %s
        """, (seller_no,))
        
        seller = cursor.fetchone()
        
        if seller:
            # Insert seller data into the seller_information table
            cursor.execute("""
                INSERT INTO seller_information (lastname, firstname, middlename, birthday, gender, province, municipality, barangay, email, contact, shopname, username, password)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, seller)
            
            # Commit the transaction
            conn.commit()

            # Send a notification email to the seller
            email = seller[8]  #
            
            try:
                # Create the email message
                msg = Message("Seller Account Approved", sender=app.config['MAIL_USERNAME'], recipients=[email])
                msg.body = f"Dear {seller[1]},\n\nCongratulations! Your seller account for shop '{seller[10]}' has been approved. You can now start selling your products.\n\nBest regards,\nYour E-Commerce Team"
                mail.send(msg)  # Send the email
            except Exception as e:
                # If email sending fails, you can log the error or handle it gracefully
                flash(f"Failed to send email notification to seller. Error: {str(e)}", 'danger')

            # Delete the seller record from the seller_application table
            cursor.execute("""
                DELETE FROM seller_application WHERE seller_no = %s
            """, (seller_no,))
            
            # Commit the transaction
            conn.commit()

            return jsonify({'success': True, 'message': 'Seller approved successfully'})
        else:
            return jsonify({'error': 'Seller not found'}), 404
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()

############################################### Disapprove seller
@app.route('/disapprove_seller/<int:seller_no>', methods=['POST'])
def disapprove_seller(seller_no):
    reason = request.json.get('reason')  # Get the reason from the request body
    if not reason:
        return jsonify({'error': 'Reason for disapproval is required.'}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Fetch seller details from the seller_application table
        cursor.execute("""
            SELECT seller_no, lastname, firstname, middlename, birthday, gender, province, municipality, barangay, email, contact, shopname, username, password
            FROM seller_application
            WHERE seller_no = %s
        """, (seller_no,))
        seller = cursor.fetchone()

        if seller:
            # Insert seller data into the seller_application_archive table
            cursor.execute("""
                INSERT INTO seller_application_archive (seller_no, lastname, firstname, middlename, birthday, gender, province, municipality, barangay, email, contact, shopname, username, password, disapproval_reason)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, seller + (reason,))
            conn.commit()

            # Send email to the seller with the reason for disapproval
            email = seller[9]  # Email address is the 10th field in the fetched data
            seller_name = f"{seller[2]} {seller[1]}"  # Construct full name (Firstname Lastname)

            try:
                msg = Message(
                    subject="Seller Application Disapproved",
                    sender=app.config['MAIL_USERNAME'],
                    recipients=[email]
                )
                msg.body = f"""
Dear {seller_name},

We regret to inform you that your seller application for the shop '{seller[11]}' has been disapproved. The reason provided is as follows:

{reason}

If you have any questions or wish to appeal, please feel free to contact us.

Best regards,
E-Commerce Team
"""
                mail.send(msg)  # Send the email
            except Exception as e:
                flash(f"Failed to send email notification to the seller. Error: {str(e)}", 'danger')

            # Delete the seller record from the seller_application table
            cursor.execute("DELETE FROM seller_application WHERE seller_no = %s", (seller_no,))
            conn.commit()

            return jsonify({'success': True, 'message': 'Seller disapproved successfully'})
        else:
            return jsonify({'error': 'Seller not found'}), 404
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()


################################################################ For checkout name address contact

@app.route('/get_buyer_info', methods=['GET'])
def get_buyer_info():
    user_id = session.get('user_id')  # Assuming user_id is stored in session
    if not user_id:
        return jsonify({'success': False, 'error': 'User not logged in'}), 401

    connection = get_db_connection()
    cursor = connection.cursor()

    query = """
    SELECT name, phonenumber, address 
    FROM buyer_information 
    WHERE user_id = %s
    """
    cursor.execute(query, (user_id,))
    result = cursor.fetchone()
    cursor.close()
    connection.close()

    if result:
        name, phone_number, address = result
        return jsonify({'success': True, 'name': name, 'phone_number': phone_number, 'address': address})
    else:
        return jsonify({'success': False, 'error': 'Buyer information not found'}), 404


################################################################ order confirmation function

@app.route('/order_confirmation')
def order_confirmation():
    order_data = session.get('order_data')
    if not order_data:
        return redirect(url_for('show_products'))  # Redirect if no order data is found

    shipping_fee = 50.00  # You can adjust this as needed
    total_amount_with_shipping = order_data['total_amount'] + shipping_fee

    # Update the order data with the new total
    order_data['total_amount'] = total_amount_with_shipping
    order_data['shipping_fee'] = shipping_fee

    return render_template('orderconfirm.html', order_data=order_data)



################################################################ 
@app.route("/fetch_checkout_data")
def fetch_checkout_data():
    conn = get_db_connection()
    user_id = session.get("user_id")  # Assuming the user is logged in and user_id is stored in session
    cursor = conn.cursor()

    cursor.execute(
        "SELECT productid, productimage, productname, productprice, productqty FROM cart WHERE user_id = %s",
        (user_id,)
    )
    cart_items = cursor.fetchall()
    cursor.close()
    conn.close()

    # Convert data into a dictionary format to send as JSON
    cart_data = [
        {
            "productid": item[0],
            "productimage": item[1],
            "productname": item[2],
            "productprice": item[3],
            "productqty": item[4]
        }
        for item in cart_items
    ]

    return jsonify(cart_data)

############################################################## for placing order

@app.route('/place_order', methods=['POST'])
def place_order():
    # Ensure the user is logged in
    if 'user_id' not in session:
        return jsonify({'success': False, 'message': 'User not logged in'})

    user_id = session['user_id']
    total_amount = request.json['total_amount']
    ordered_items = request.json['ordered_items']
    ordered_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    # Extract seller_id from the first item in the ordered items list
    seller_id = ordered_items[0]['sellerid'] if ordered_items else None

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
            """, (order_id, item['productid'], item['productname'], item['productprice'], item['productqty'], item['subtotal'], item['sellerid']))

            # Remove the item from the cart
            cartid = item['cartid']
            cursor.execute("DELETE FROM cart WHERE cartid = %s", (cartid,))
        
        conn.commit()

        # Store order data in session, including image
        order_data = {
            'total_amount': total_amount,
            'ordered_items': ordered_items  # Include product image
        }
        session['order_data'] = order_data  # Save order data in session

        return jsonify({'success': True, 'message': 'Order placed successfully!'})

    except Exception as e:
        conn.rollback()  # Rollback in case of error
        return jsonify({'success': False, 'message': str(e)})

    finally:
        cursor.close()
        conn.close()

# ###################################################### order page for seller

@app.route('/orders')
def orders():

    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    seller_id = session.get('seller_id')  
    if not seller_id:
        return redirect(url_for('login')) 

    query = """
        SELECT 
            oi.order_id,
            o.user_id,
            b.name AS buyer_name,
            oi.productid,
            oi.productname,
            oi.productprice,
            oi.productqty,
            (oi.productprice * oi.productqty) AS subtotal,
            o.ordered_date,
            o.shipped_date,
            o.received_date,
            o.status
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        JOIN buyer_information b ON o.user_id = b.user_id
        WHERE oi.seller_id = %s
        ORDER BY o.ordered_date DESC
    """
    cursor.execute(query, (seller_id,))
    orders = cursor.fetchall()

    cursor.execute("""
        SELECT message, link, created_at 
        FROM seller_notif 
        WHERE seller_id = %s 
        ORDER BY created_at DESC
    """, (seller_id,))
    notifications = cursor.fetchall()  # Notifications as dictionaries

    connection.close()

    return render_template('orders.html', orders=orders, notifications=notifications)

# ############################# for updating order status in seller page
@app.route('/update_order_status', methods=['POST'])
def update_order_status():

    data = request.get_json()
    order_id = data.get('order_id')
    new_status = data.get('status')

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        current_datetime = datetime.now()
        
        # Update query based on status
        if new_status == "Ready for pick up":
            query = """
                UPDATE orders 
                SET status = %s 
                WHERE order_id = %s
            """
            
            cursor.execute(query, (new_status, order_id))

            # Fetch user_id from orders table based on order_id
            fetch_user_query = "SELECT user_id FROM orders WHERE order_id = %s"
            cursor.execute(fetch_user_query, (order_id,))
            result = cursor.fetchone()

            if result:  # Ensure the order exists
                user_id = result[0]
                
                # Insert notification for the buyer
                notification_message = "Seller is preparing to ship your order!"
                notification_link = f"/my_orders"
                insert_notification_query = """
                    INSERT INTO buyer_notif (user_id, message, link, is_read, created_at)
                    VALUES (%s, %s, %s, 0, NOW())
                """
                cursor.execute(insert_notification_query, (user_id, notification_message, notification_link))

        elif new_status == "Delivered":
            query = """
                UPDATE orders 
                SET status = %s, received_date = %s 
                WHERE order_id = %s
            """
            cursor.execute(query, (new_status, current_datetime, order_id))
        else:
            query = "UPDATE orders SET status = %s WHERE order_id = %s"
            cursor.execute(query, (new_status, order_id))

        fetch_orders_query = """
            SELECT order_id, user_id, seller_id 
            FROM orders 
            WHERE status = 'Ready for pick up'
        """
        cursor.execute(fetch_orders_query)
        orders = cursor.fetchall()

        for order in orders:
            order_id, user_id, seller_id = order

            # Fetch seller details
            fetch_seller_query = """
                SELECT shopname, 
                    CONCAT(barangay, ', ', municipality, ', ', province) AS seller_address
                FROM seller_information 
                WHERE seller_id = %s
            """
            cursor.execute(fetch_seller_query, (seller_id,))
            seller_data = cursor.fetchone()

            if seller_data:
                shopname, seller_address = seller_data

                # Fetch buyer details
                fetch_buyer_query = """
                    SELECT name AS buyer, phonenumber, address AS buyer_address 
                    FROM buyer_information 
                    WHERE user_id = %s
                """
                cursor.execute(fetch_buyer_query, (user_id,))
                buyer_data = cursor.fetchone()

                if buyer_data:
                    buyer_name, phone_number, buyer_address = buyer_data

                    # Check if the order already exists in for_pickup
                    check_existing_query = """
                        SELECT order_id FROM for_pickup WHERE order_id = %s
                    """
                    cursor.execute(check_existing_query, (order_id,))
                    existing_order = cursor.fetchone()

                    if not existing_order:
                        # Insert into for_pickup table
                        insert_for_pickup_query = """
                            INSERT INTO for_pickup (date, seller_id, shopname, seller_address, order_id, buyer, buyer_address, phonenumber)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        """
                        cursor.execute(insert_for_pickup_query, 
                                    (current_datetime, seller_id, shopname, seller_address, order_id, buyer_name, buyer_address, phone_number))


        connection.commit()
        cursor.close()
        connection.close()
        return jsonify({"success": True})
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"success": False})


######################################### buyers order

@app.route('/my_orders')
def my_orders():
    # Check if the user is logged in
    user_id = session.get('user_id')
    if not user_id:
        return redirect(url_for('login'))  # Redirect to login if no user is logged in

    # Establish DB connection
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    # SQL query to fetch order details along with product image
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
            o.shipped_date,  # Add shipped_date
            o.received_date  # Add received_date
        FROM order_items oi
        JOIN products p ON oi.productid = p.productid 
        JOIN orders o ON oi.order_id = o.order_id  
        WHERE o.user_id = %s
        ORDER BY o.order_id DESC  
    """
    cursor.execute(query, (user_id,))
    order_items = cursor.fetchall()

    # Fetch notifications for the logged-in user
    query_notifications = """
        SELECT message, link, created_at 
        FROM buyer_notif 
        WHERE user_id = %s 
        ORDER BY created_at DESC
    """
    cursor.execute(query_notifications, (user_id,))
    notifications = cursor.fetchall()

    cursor.close()
    connection.close()

    to_receive_orders = {}
    to_ship_orders = {}
    completed_orders = {}
    cancelled_orders = {}

    grouped_orders = {}

    for item in order_items:
        order_id = item['order_id']

        if order_id not in grouped_orders:
            grouped_orders[order_id] = {
                'seller_id': item['seller_id'],  # Add seller_id here
                'ordered_date': item['ordered_date'],
                'shipped_date': item.get('shipped_date'),  # Add shipped date
                'received_date': item.get('received_date'),  # Add received date
                'items': [],
                'total': item['total'] + 50,
                'statuses': set(),
            }

        grouped_orders[order_id]['items'].append(item)
        grouped_orders[order_id]['statuses'].add(item['status'])

# Separate orders into different categories
    for order_id, order_data in grouped_orders.items():
        statuses = order_data['statuses']

        if statuses == {'Pending'} or statuses == {'Ready for pick up'} :
            to_ship_orders[order_id] = order_data
        elif statuses == {'Shipped'} or statuses == {'Picked up'} and not statuses.intersection({'pending'}) :
        #elif 'Shipped' in statuses and not statuses.intersection({'pending'}):
            to_receive_orders[order_id] = order_data
        elif statuses == {'Received'}:
            completed_orders[order_id] = order_data
        elif statuses == {'Cancelled'}:
            cancelled_orders[order_id] = order_data

    return render_template(
        'myorders.html', 
        to_receive_orders=to_receive_orders,
        to_ship_orders=to_ship_orders,
        completed_orders=completed_orders,
        cancelled_orders=cancelled_orders, 
        notifications=notifications
    )

########################################### cancel order

@app.route('/cancel_order', methods=['POST'])
def cancel_order():
    try:
        # Get data from the form
        order_id = request.form.get('order_id')
        user_id = session.get('user_id')
        ordered_date = request.form.get('ordered_date')
        reason = request.form.get('reason')

        # Database connection
        conn = get_db_connection()
        cursor = conn.cursor()

        # Insert the cancel request
        query = """
        INSERT INTO cancel_requests (order_id, user_id, ordered_date, reason, request_date)
        VALUES (%s, %s, %s, %s, %s)
        """
        cursor.execute(query, (order_id, user_id, ordered_date, reason, datetime.now()))
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({'success': True, 'message': 'Wait for the seller to approve your request'})
    except Exception as e:
        print(e)
        return jsonify({'success': False, 'message': 'An error occurred while processing the cancel request.'})
    
########################################## check cancel request

@app.route('/check_cancel_request', methods=['POST'])
def check_cancel_request():
    order_id = request.json.get('order_id')
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    query = "SELECT COUNT(*) AS count FROM cancel_requests WHERE order_id = %s"
    cursor.execute(query, (order_id,))
    result = cursor.fetchone()

    cursor.close()
    connection.close()

    if result['count'] > 0:
        return jsonify({'exists': True})
    else:
        return jsonify({'exists': False})

################################################### request order cancellation

@app.route('/requests')
def requests():
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    seller_id = session.get('seller_id')

    # Query to get data from cancel_requests and buyer_information
    query = """
        SELECT 
            c.order_id, 
            c.user_id, 
            b.name, 
            c.ordered_date, 
            c.request_date, 
            c.reason, 
            c.status 
        FROM cancel_requests c
        JOIN buyer_information b ON c.user_id = b.user_id
    """
    cursor.execute(query)
    cancel_requests_data = cursor.fetchall()

    cursor.execute("""
        SELECT message, link, created_at 
        FROM seller_notif 
        WHERE seller_id = %s 
        ORDER BY created_at DESC
    """, (seller_id,))
    notifications = cursor.fetchall()  # Notifications as dictionaries


    cursor.close()
    connection.close()

    # Pass the data to the template
    return render_template('requests.html', cancel_requests_data=cancel_requests_data, notifications=notifications)

######################################################### Approve cancellation

@app.route('/approve_cancel_order', methods=['POST'])
def approve_cancel_order():
    data = request.json
    order_id = data.get('order_id')

    try:
        
        connection = get_db_connection()
        cursor = connection.cursor()

        cursor.execute("SELECT user_id FROM orders WHERE order_id = %s", (order_id,))
        result = cursor.fetchone()

        if result:
            user_id = result[0]  
            
            query_update_order = """
                UPDATE orders
                SET status = 'Cancelled'
                WHERE order_id = %s
            """
            cursor.execute(query_update_order, (order_id,))

           
            query_delete_request = """
                DELETE FROM cancel_requests
                WHERE order_id = %s
            """
            cursor.execute(query_delete_request, (order_id,))

            notification_message = "Your cancellation request has been approved"
            notification_link = f"/my_orders" 
            query_insert_notification = """
                INSERT INTO buyer_notif (user_id, message, link, is_read, created_at)
                VALUES (%s, %s, %s, 0, NOW())
            """
            cursor.execute(query_insert_notification, (user_id, notification_message, notification_link))

           
            connection.commit()

            return jsonify({'success': True})
        else:
            return jsonify({'success': False, 'message': 'Order not found'})

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'success': False, 'message': 'An error occurred while processing the request.'})

    finally:
        cursor.close()
        connection.close()

############################################### disapprove order

@app.route('/disapprove_cancel_order', methods=['POST'])
def disapprove_cancel_order():
    data = request.json
    order_id = data.get('order_id')
    disapprove_reason = data.get('disapprove_reason')

    if disapprove_reason == "Other":
        other_reason = data.get('other_reason')
        disapprove_reason = other_reason if other_reason else disapprove_reason

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        cursor.execute("SELECT user_id FROM orders WHERE order_id = %s", (order_id,))
        result = cursor.fetchone()

        if result:
            user_id = result[0]

            # Update the status in cancel_requests
            query_update_request = """
                UPDATE cancel_requests
                SET status = 'Disapproved', disapprove_reason = %s
                WHERE order_id = %s
            """
            cursor.execute(query_update_request, (disapprove_reason, order_id))

            # Add a notification to the buyer
            notification_message = f"Your cancellation request has been disapproved due to: {disapprove_reason}"
            notification_link = "/my_orders"
            query_insert_notification = """
                INSERT INTO buyer_notif (user_id, message, link, is_read, created_at)
                VALUES (%s, %s, %s, 0, NOW())
            """
            cursor.execute(query_insert_notification, (user_id, notification_message, notification_link))

            connection.commit()

            return jsonify({'success': True})

        else:
            return jsonify({'success': False, 'message': 'Order not found'})

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'success': False, 'message': 'An error occurred while processing the request.'})

    finally:
        cursor.close()
        connection.close()


########################################################## updating order to received by the buyer

@app.route('/order-received/<int:order_id>', methods=['POST']) 
def mark_order_received(order_id):
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
        notification_link = f"/orders"
        query_insert_notification = """
            INSERT INTO seller_notif (seller_id, message, link, created_at)
            VALUES (%s, %s, %s, NOW())
        """
        cursor.execute(query_insert_notification, (seller_id, notification_message, notification_link))

        connection.commit()

        return jsonify({"success": True, "message": "Order marked as received."})

    except Exception as e:
        connection.rollback()
        return jsonify({"success": False, "error": str(e)})

    finally:
        cursor.close()
        connection.close()

################################################################## Sales report 

@app.route('/sales')
def sales():
    try:

        # Connect to the database
        conn = get_db_connection()
        cursor = conn.cursor()

        # Query for Order Sales
        cursor.execute("""
            SELECT 
                DATE(o.received_date) AS received_date,
                oi.order_id,
                oi.productname,
                oi.seller_id,
                o.user_id,
                oi.subtotal,
                ROUND(oi.subtotal - ((oi.subtotal / 100) * (oi.productqty * 10)), 2) AS seller_income,
                ROUND((oi.subtotal / 100) * (oi.productqty * 10), 2) AS admin_income
            FROM order_items oi
            INNER JOIN orders o ON oi.order_id = o.order_id
            WHERE o.status = 'Received'
        """)

        
        order_sales = cursor.fetchall()

        # Query for Total Orders (Pending and Shipped)
        cursor.execute("""
            SELECT COUNT(*) AS total_orders
            FROM orders
            WHERE status IN ('Pending', 'Shipped')
        """)
        total_orders = cursor.fetchone()[0]

        # Query for Total Revenue (Received Orders)
        cursor.execute("""
            SELECT SUM(total) AS total_revenue
            FROM orders
            WHERE status = 'Received'
        """)
        total_revenue = cursor.fetchone()[0] or 0  # Ensure it's not None

        # Query for Total Products Sold (Received Orders)
        cursor.execute("""
            SELECT SUM(oi.productqty) AS total_products_sold
            FROM order_items oi
            INNER JOIN orders o ON oi.order_id = o.order_id
            WHERE o.status = 'Received'
        """)
        total_products_sold = cursor.fetchone()[0] or 0  # Ensure it's not None

        # Query for Admin Commission
        cursor.execute("""
            SELECT SUM(admin_income) AS total_admin_commission
            FROM admin_commission
        """)
        total_admin_commission = cursor.fetchone()[0] or 0  # Ensure it's not None

        cursor.execute('SELECT message, link FROM notifications WHERE is_read = FALSE ORDER BY created_at DESC')
        notifications = cursor.fetchall()

        notifications_data = [{'message': notification[0], 'link': notification[1]} for notification in notifications]

        conn.close()

        # Pass all the data to the template
        return render_template(
            'sales.html',
            order_sales=order_sales,
            total_orders=total_orders,
            total_revenue=total_revenue,
            total_products_sold=total_products_sold,
            total_admin_commission=total_admin_commission,
            notifications=notifications_data
        )
    except Exception as e:
        return f"An error occurred: {str(e)}"

################################################################## For Sending feedback

@app.route('/submit_feedback', methods=['POST'])
def submit_feedback():

    feedback_data = request.get_json()
    product_quality_message = feedback_data['product_quality']
    seller_service_message = feedback_data['seller_service']
    delivery_speed_message = feedback_data['delivery_speed']
    product_id = feedback_data['product_id']

    rating_mapping = {
        "Terrible": 1,
        "Poor": 2,
        "Fair": 3,
        "Good": 4,
        "Amazing": 5
    }

    # Convert the message ratings to numbers
    product_quality = rating_mapping.get(product_quality_message, 0)
    seller_service = rating_mapping.get(seller_service_message, 0)
    delivery_speed = rating_mapping.get(delivery_speed_message, 0)

    # Validate feedback values
    if not (1 <= product_quality <= 5 and 1 <= seller_service <= 5 and 1 <= delivery_speed <= 5):
        return jsonify({"message": "Error: Feedback values must be between 1 and 5!"}), 400

    # Get database connection
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Get current product quality (default to 0 if NULL)
        cursor.execute("""
            SELECT COALESCE(product_quality, 0), COALESCE(feedback, 0)
            FROM products
            WHERE productid = %s
        """, (product_id,))
        result = cursor.fetchone()

        if result is None:
            return jsonify({"message": "Error: Product not found!"}), 404

        current_product_quality, current_feedback = result

        # Update product quality and feedback count
        updated_product_quality = current_product_quality + product_quality
        updated_feedback = current_feedback + 1  # Increment feedback count by 1
        cursor.execute("""
            UPDATE products
            SET product_quality = %s, feedback = %s
            WHERE productid = %s
        """, (updated_product_quality, updated_feedback, product_id))

        # Get seller_id from the products table
        cursor.execute("""
            SELECT seller_id
            FROM products
            WHERE productid = %s
        """, (product_id,))
        seller_id = cursor.fetchone()[0]

        # Get current seller ratings and feedback count (default to 0 if NULL)
        cursor.execute("""
            SELECT COALESCE(seller_service, 0), COALESCE(delivery_speed, 0), COALESCE(feedback, 0)
            FROM sales
            WHERE seller_id = %s
        """, (seller_id,))
        current_seller_service, current_delivery_speed, current_seller_feedback = cursor.fetchone()

        # Update seller ratings and feedback count
        updated_seller_service = current_seller_service + seller_service
        updated_delivery_speed = current_delivery_speed + delivery_speed
        updated_seller_feedback = current_seller_feedback + 1  # Increment seller feedback count by 1

        cursor.execute("""
            UPDATE sales
            SET seller_service = %s, delivery_speed = %s, feedback = %s
            WHERE seller_id = %s
        """, (updated_seller_service, updated_delivery_speed, updated_seller_feedback, seller_id))

        # Commit the changes
        conn.commit()

        return jsonify({"message": "Feedback submitted successfully!"}), 200

    except Exception as e:
        conn.rollback()  # Roll back changes on error
        print("Error:", e)
        return jsonify({"message": "Error submitting feedback!"}), 500

    finally:
        cursor.close()
        conn.close()

################################################### code for chat

@app.route('/get_chat_messages', methods=['GET'])
def get_chat_messages():
    seller_id = request.args.get('seller_id')
    user_id = session.get('user_id')

    if not seller_id or not user_id:
        return jsonify({"error": "Missing seller_id or user_id"}), 400

    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    try:
        # Query to fetch messages between the buyer and the seller
        query = """
            SELECT sender_role, message_text, timestamp
            FROM messages
            WHERE 
                (user_id = %s AND seller_id = %s) 
                OR (user_id = %s AND seller_id = %s)
            ORDER BY timestamp ASC
        """
        cursor.execute(query, (user_id, seller_id, seller_id, user_id))
        messages = cursor.fetchall()

        if not messages:
            return jsonify([])  # No messages, return an empty list
        
        return jsonify(messages)

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        connection.close()


#################################################### send message function

@app.route('/send_message', methods=['POST'])
def send_message():
    data = request.json
    seller_id = data.get('seller_id')
    user_id = session.get('user_id')
    order_id = data.get('order_id')  # Retrieve order ID
    sender_role = 'buyer'  # Assuming the buyer is sending this message
    message_text = data.get('message')

    if not seller_id or not message_text:
        return jsonify({'success': False, 'error': 'Seller ID and message text are required.'}), 400

    connection = get_db_connection()
    cursor = connection.cursor()

    # Insert message into the database
    query = """
        INSERT INTO messages (order_id, user_id, seller_id, sender_role, message_text, timestamp)
        VALUES (%s, %s, %s, %s, %s, %s)
    """
    cursor.execute(query, (order_id, user_id, seller_id, sender_role, message_text, datetime.now()))
    connection.commit()

    cursor.close()
    connection.close()

    return jsonify({'success': True, 'message': 'Message sent successfully.'})

######################################### get message for seller

@app.route('/fetch_messages', methods=['GET'])
def fetch_messages():
    try:
        seller_id = session.get('seller_id')  # Get the logged-in seller's ID from the session

        if not seller_id:
            return jsonify({"error": "Unauthorized access"}), 401

        # Connect to the database
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # Query to fetch messages and buyer names
        query = """
            SELECT m.message_id, m.message_text, m.timestamp, b.name AS sender_name
            FROM messages m
            JOIN buyer_information b ON m.user_id = b.user_id
            WHERE m.seller_id = %s
            ORDER BY m.timestamp DESC
        """
        cursor.execute(query, (seller_id,))
        messages = cursor.fetchall()

        cursor.close()
        connection.close()

        return jsonify({"messages": messages})
    except Exception as e:
        print(f"Error fetching messages: {e}")
        return jsonify({"error": "Internal Server Error"}), 500

#################################################### buyer message to seller
@app.route('/fetch_buyer_messages/<string:sender_name>', methods=['GET'])
def fetch_buyer_messages(sender_name):
    try:
        seller_id = session.get('seller_id')
        if not seller_id:
            return jsonify({"error": "Unauthorized access"}), 401

        # Connect to DB
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # Fetch messages with their role information directly
        query_messages = """
            SELECT m.message_id, m.order_id, m.message_text, m.timestamp, m.user_id, m.sender_role
            FROM messages m
            WHERE m.seller_id = %s AND m.user_id IN (
                SELECT user_id FROM buyer_information WHERE name = %s
            )
            ORDER BY m.timestamp ASC
        """
        cursor.execute(query_messages, (seller_id, sender_name))
        messages = cursor.fetchall()

        # If roles exist, filter based on `sender_role`
        order_ids = [msg['order_id'] for msg in messages if msg['order_id'] is not None]

        # Fetch order details only if buyer's role is not a "seller"
        if order_ids:
            order_query = """
                SELECT oi.order_id, oi.productname, oi.productprice, p.productimage
                FROM order_items oi
                LEFT JOIN products p ON oi.productid = p.productid
                WHERE oi.order_id IN ({})
            """.format(",".join(["%s"] * len(order_ids)))

            cursor.execute(order_query, order_ids)
            order_details = cursor.fetchall()
            order_dict = {order['order_id']: order for order in order_details}
        else:
            order_dict = {}

        cursor.close()
        connection.close()

        # Attach order details selectively unless it's a seller
        for msg in messages:
            if msg['sender_role'] == "seller":
                msg['order_details'] = None  # Exclude order details for sellers
            else:
                msg['order_details'] = order_dict.get(msg['order_id'], None)

        return jsonify({"messages": messages})

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": "Internal server error"}), 500


################################################# seller reply functions

@app.route('/reply_message', methods=['POST'])
def reply_message():
    try:
        # Get data from POST request
        data = request.get_json()
        user_id = data.get('user_id')
        message_text = data.get('message_text')
        seller_id = session.get('seller_id')  # Get seller ID from session
        sender_role = 'seller'
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Insert into database
        conn = get_db_connection()
        cursor = conn.cursor()
        query = """
            INSERT INTO messages (user_id, seller_id, sender_role, message_text, timestamp)
            VALUES (%s, %s, %s, %s, %s)
        """
        cursor.execute(query, (user_id, seller_id, sender_role, message_text, timestamp))
        conn.commit()
        conn.close()
        
        return jsonify({"success": True})
    except Exception as e:
        print("Error sending reply:", e)
        return jsonify({"success": False, "error": str(e)}), 500

########################################################## seller sales
@app.route('/sellersales')
def sellersales():
    try:

        # Connect to the database
        conn = get_db_connection()
        cursor = conn.cursor()

        # Query for Order Sales
        cursor.execute("""
            SELECT 
                DATE(o.received_date) AS received_date,
                oi.order_id,
                oi.productname,
                oi.seller_id,
                o.user_id,
                oi.subtotal,
                ROUND(oi.subtotal - ((oi.subtotal / 100) * (oi.productqty * 10)), 2) AS seller_income,
                ROUND((oi.subtotal / 100) * (oi.productqty * 10), 2) AS admin_income
            FROM order_items oi
            INNER JOIN orders o ON oi.order_id = o.order_id
            WHERE o.status = 'Received'
        """)

        
        order_sales = cursor.fetchall()

        # Query for Total Orders (Pending and Shipped)
        cursor.execute("""
            SELECT COUNT(*) AS total_orders
            FROM orders
            WHERE status IN ('Pending', 'Shipped')
        """)
        total_orders = cursor.fetchone()[0]

        # Query for Total Revenue (Received Orders)
        cursor.execute("""
            SELECT SUM(total) AS total_revenue
            FROM orders
            WHERE status = 'Received'
        """)
        total_revenue = cursor.fetchone()[0] or 0  # Ensure it's not None

        # Query for Total Products Sold (Received Orders)
        cursor.execute("""
            SELECT SUM(oi.productqty) AS total_products_sold
            FROM order_items oi
            INNER JOIN orders o ON oi.order_id = o.order_id
            WHERE o.status = 'Received'
        """)
        total_products_sold = cursor.fetchone()[0] or 0  # Ensure it's not None

        # Query for Admin Commission
        cursor.execute("""
            SELECT SUM(admin_income) AS total_admin_commission
            FROM admin_commission
        """)
        total_admin_commission = cursor.fetchone()[0] or 0  # Ensure it's not None

        cursor.execute('SELECT message, link FROM notifications WHERE is_read = FALSE ORDER BY created_at DESC')
        notifications = cursor.fetchall()

        notifications_data = [{'message': notification[0], 'link': notification[1]} for notification in notifications]

        conn.close()

        # Pass all the data to the template
        return render_template(
            'sellersales.html',
            order_sales=order_sales,
            total_orders=total_orders,
            total_revenue=total_revenue,
            total_products_sold=total_products_sold,
            total_admin_commission=total_admin_commission,
            notifications=notifications_data
        )
    except Exception as e:
        return f"An error occurred: {str(e)}"
    
########################################################## courier side
@app.route('/courierdb')
def courierdb():
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # Fetch orders with status "Pending" or "Picked up" for To-Pickup tab
        query_pickup = "SELECT * FROM for_pickup WHERE status IN ('Pending', 'Picked up')"
        cursor.execute(query_pickup)
        pickup_orders = cursor.fetchall()

        # Fetch orders with status "Delivered" for Delivered tab
        query_delivered = "SELECT * FROM for_pickup WHERE status = 'Delivered'"
        cursor.execute(query_delivered)
        delivered_orders = cursor.fetchall()

        cursor.close()
        connection.close()

        return render_template('courier_db.html', pickup_orders=pickup_orders, delivered_orders=delivered_orders)
    except Exception as e:
        print(f"Error: {e}")
        return render_template('courier_db.html', pickup_orders=[], delivered_orders=[])


################################################ updating pick up status

@app.route('/update_pickup_status', methods=['POST'])
def update_pickup_status():
    try:
        data = request.get_json()
        order_id = data['order_id']
        new_status = data['status']

        conn = get_db_connection()
        cursor = conn.cursor()

        # Update the status in the database
        update_query = "UPDATE for_pickup SET status = %s WHERE order_id = %s"
        cursor.execute(update_query, (new_status, order_id))
        conn.commit()

        # Update the status in the database
        update_query1 = "UPDATE orders SET status = %s WHERE order_id = %s"
        cursor.execute(update_query1, (new_status, order_id))
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

if __name__ == "__main__":
    app.run(debug=True)