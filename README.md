# User CRUD Management Application

A simple yet elegant Spring Boot CRUD (Create, Read, Update, Delete) web application for managing users with their names and addresses.

## 🎯 Features

- ✅ **Create** - Add new users with name and address
- ✅ **Read** - View all users in a responsive table
- ✅ **Update** - Edit existing user information
- ✅ **Delete** - Remove users with confirmation dialog
- ✅ **Modern UI** - Beautiful Thymeleaf-based interface with gradient styling
- ✅ **In-Memory Database** - H2 database for quick testing
- ✅ **Spring Data JPA** - Easy data persistence layer

## 🛠️ Technologies Used

- **Java 17** - Programming language
- **Spring Boot 3.3.0** - Framework
- **Spring Data JPA** - ORM framework
- **Thymeleaf** - Template engine for UI
- **H2 Database** - In-memory relational database
- **Maven** - Build tool
- **Tomcat** - Embedded web server (port 8080)

## 📋 Project Structure

```
springapp/
├── src/
│   ├── main/
│   │   ├── java/com/example/
│   │   │   ├── UserCrudApplication.java      # Main Spring Boot app
│   │   │   ├── controller/
│   │   │   │   └── UserController.java       # REST/Web controller
│   │   │   ├── model/
│   │   │   │   └── User.java                 # User entity
│   │   │   ├── repository/
│   │   │   │   └── UserRepository.java       # JPA repository
│   │   │   └── service/
│   │   │       └── UserService.java          # Business logic
│   │   └── resources/
│   │       ├── application.properties        # App configuration
│   │       └── templates/
│   │           └── index.html                # Thymeleaf UI template
│   └── test/
├── pom.xml                                   # Maven dependencies
├── .gitignore                                # Git ignore file
└── README.md                                 # This file
```

## 🚀 Quick Start

### Prerequisites

- Java 17 or higher
- Maven 3.6+
- Git

### Installation & Running

1. **Clone the repository**
   ```bash
   git clone git@github.com:cloudnextai/springapp.git
   cd springapp
   ```

2. **Build the application**
   ```bash
   mvn clean install
   ```

3. **Run the application**
   ```bash
   export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
   java -jar target/user-crud-app-1.0.0.jar
   ```

4. **Access the application**
   - Open your browser and navigate to: **http://localhost:8080/users**
   - The application will load with an empty user list

### Docker & Container Deployment

For containerization and cloud deployment, see [DOCKER.md](DOCKER.md) for detailed instructions on:
- Building Docker images
- Running with Docker Compose
- Deploying to cloud platforms (AWS, Azure, GCP, Kubernetes)

**Quick Start with Docker:**
```bash
# Build image
docker build -t user-crud-app:latest .

# Run with Docker Compose
docker-compose up -d

# Access at http://localhost:8080/users
```

## 📱 Usage

### Adding a User
1. Enter the user's **Name** in the first field
2. Enter the user's **Address** in the second field
3. Click the **Add User** button
4. The user will be added to the database and displayed in the table

### Editing a User
1. Click the **Edit** button next to the user you want to modify
2. The form will populate with the user's current data
3. Update the name or address
4. Click **Update User**
5. Click **Cancel** to discard changes

### Deleting a User
1. Click the **Delete** button next to the user
2. Confirm the deletion in the popup dialog
3. The user will be removed from the database

## 🏗️ API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users` | Display all users and add user form |
| POST | `/users` | Add a new user |
| GET | `/users/{id}/edit` | Load user edit form |
| POST | `/users/{id}` | Update user details |
| GET | `/users/{id}/delete` | Delete a user |

## 🗄️ Database

The application uses **H2 in-memory database** with automatic schema creation.

### User Table Schema
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL
);
```

**H2 Console:**
- URL: `http://localhost:8080/h2-console`
- Database: `jdbc:h2:mem:testdb`
- Username: `sa`
- Password: (leave blank)

## 🔧 Configuration

All configuration is in `src/main/resources/application.properties`:

```properties
spring.application.name=user-crud-app
server.port=8080

# Database
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa

# JPA/Hibernate
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.show-sql=false

# H2 Console
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console
```

## 📦 Dependencies

- `spring-boot-starter-web` - Web and REST support
- `spring-boot-starter-thymeleaf` - Template engine
- `spring-boot-starter-data-jpa` - JPA/ORM support
- `h2` - In-memory database
- `spring-boot-devtools` - Development tools
- `spring-boot-starter-test` - Testing framework

## 🎨 UI Features

- **Responsive Design** - Works on desktop, tablet, and mobile
- **Gradient Background** - Purple gradient theme
- **Smooth Animations** - Hover effects and transitions
- **Form Validation** - Client-side input validation
- **Table Display** - Clean, organized user list
- **Action Buttons** - Easy-to-use Edit and Delete buttons with icons
- **Empty State Message** - Helpful message when no users exist

## 🐛 Troubleshooting

### Application won't start
- Make sure Java 17 is installed: `java -version`
- Check port 8080 is available
- Try rebuilding: `mvn clean install`

### Cannot connect to database
- H2 database is in-memory, so data is lost on restart
- Check `application.properties` configuration

### SSH Push Fails
- Ensure SSH key is added to GitHub
- Test connection: `ssh -T git@github.com`

## 📝 Development Notes

- Data is stored in H2 in-memory database (cleared on restart)
- For production, replace H2 with PostgreSQL or MySQL
- Lombok dependency has been removed to avoid Java 25 compatibility issues
- Manual getters/setters are used in the User model

## 🚀 Future Enhancements

- [ ] Add email field to User model
- [ ] Implement phone number with validation
- [ ] Add user search/filter functionality
- [ ] Implement pagination for large datasets
- [x] ✅ Add REST API endpoints with RESTful design
- [x] ✅ Docker containerization with multi-stage build
- [ ] Setup CI/CD pipeline (GitHub Actions)
- [ ] Create separate REST API controller (JSON responses)
- [ ] Add data validation with @Valid annotations
- [ ] Implement error handling and custom error pages
- [ ] Add unit and integration tests
- [ ] Switch to persistent database (PostgreSQL/MySQL)

## 📄 License

This project is open source and available for educational purposes.

## 👨‍💻 Author

Created as a learning project for Spring Boot and CRUD operations.