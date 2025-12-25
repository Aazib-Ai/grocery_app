import '../models/user_profile.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class MockRepository {
  static UserProfile getUserProfile() {
    return UserProfile(
      name: "Ali Raza",
      email: "aliirtiza@gmail.com",
      address: "Airport road, stree No 12 kashrot Giligit.",
      phone: "+923555675487",
      imageUrl: "assets/images/user_avatar.png",
    );
  }

  static List<CartItem> getCartItems() {
    return [
      CartItem(
        id: '1',
        name: "Veggie tomato mix",
        price: 1900,
        imageUrl: "assets/images/product_placeholder.png", 
        quantity: 1,
      ),
      CartItem(
        id: '2',
        name: "Fish with mix orange",
        price: 1900,
        imageUrl: "assets/images/product_placeholder.png",
        quantity: 1,
      ),
    ];
  }

  static List<CartItem> getFavoriteItems() {
    return [
      CartItem(
        id: '1',
        name: "Veggie tomato mix",
        price: 1900,
        imageUrl: "assets/images/product_placeholder.png",
      ),
      CartItem(
        id: '2',
        name: "Fish with mix orange",
        price: 1900,
        imageUrl: "assets/images/product_placeholder.png",
      ),
    ];
  }
  
  static List<Map<String, String>> getFAQs() {
    return [
      {
        "question": "How can I place an order on Ali Mart?",
        "answer": "You can place an order by selecting items and proceeding to checkout."
      },
      {
        "question": "How long does delivery take?",
        "answer": "Delivery usually takes 30-45 minutes depending on your location."
      },
      {
        "question": "Can I cancel or modify my order?",
        "answer": "Yes, you can cancel before the rider picks up your order."
      },
       {
        "question": "How can I track my order?",
        "answer": "You can track your order in real-time from the Tracking screen."
      },
       {
        "question": "How do I contact customer support?",
        "answer": "You use the Help & Support form to contact us directly."
      },
    ];
  }

  static List<Product> getProducts() {
    return [
      Product(
        id: '1',
        name: "Veggie tomato mix",
        price: 1900,
        imageUrl: "assets/images/img_vegetables.png",
      ),
      Product(
        id: '2',
        name: "Egg and cucumber",
        price: 1900,
        imageUrl: "assets/images/img_vegetables.png",
      ),
      Product(
        id: '3',
        name: "Fried chicken mix",
        price: 1900,
        imageUrl: "assets/images/img_meat.png",
      ),
       Product(
        id: '4',
        name: "Moi-moi and ekpa",
        price: 1900,
        imageUrl: "assets/images/img_meat.png",
      ),
      // Fruits (reusing veggies or placeholder if no fruit img)
      // I only have veggies, meat, dairy. I will use veggies for fruits for now as they are close 'fresh produce'.
      Product(
        id: '5',
        name: "Fresh Red Apples",
        price: 450,
        imageUrl: "assets/images/product_placeholder.png", // Keep distinct placeholder for fruits since I failed to gen fruit img
      ),
      Product(
        id: '6',
        name: "Organic Bananas",
        price: 120,
        imageUrl: "assets/images/product_placeholder.png",
      ),
      Product(
        id: '7',
        name: "Juicy Oranges",
        price: 300,
        imageUrl: "assets/images/product_placeholder.png",
      ),
      // Vegetables
      Product(
        id: '8',
        name: "Fresh Broccoli",
        price: 150,
        imageUrl: "assets/images/img_vegetables.png",
      ),
      Product(
        id: '9',
        name: "Carrots 1kg",
        price: 80,
        imageUrl: "assets/images/img_vegetables.png",
      ),
      Product(
        id: '10',
        name: "Potatoes 5kg",
        price: 400,
        imageUrl: "assets/images/img_vegetables.png",
      ),
      // Dairy
      Product(
        id: '11',
        name: "Whole Milk 1L",
        price: 220,
        imageUrl: "assets/images/img_dairy.png",
      ),
      Product(
        id: '12',
        name: "Cheddar Cheese Block",
        price: 850,
        imageUrl: "assets/images/img_dairy.png",
      ),
      Product(
        id: '13',
        name: "Greek Yogurt",
        price: 350,
        imageUrl: "assets/images/img_dairy.png",
      ),
      // Bakery
      Product(
        id: '14',
        name: "Whole Wheat Bread",
        price: 180,
        imageUrl: "assets/images/product_placeholder.png", 
      ),
      Product(
        id: '15',
        name: "Chocolate Chip Cookies",
        price: 300,
        imageUrl: "assets/images/product_placeholder.png",
      ),
    ];
  }
}
