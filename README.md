# Tod API
![Tod](https://static.wikia.nocookie.net/lgbt/images/5/53/Todd_Chavez.png/revision/latest?cb=20240325205726&path-prefix=es)


A RESTful API developed with Ruby on Rails, providing crypto services using the [CoinGecko API](https://docs.coingecko.com/reference/introduction). This project uses Docker for easier development and deployment.

---

## Content

- [Tod API](#tod-api)
  - [Content](#content)
  - [Description](#description)
  - [Characteristics](#characteristics)
  - [Technologies](#technologies)
  - [Installation](#installation)
    - [Previous Requirements](#previous-requirements)
    - [Steps to Configure this Repo Locally](#steps-to-configure-this-repo-locally)

---

## Description

**Tod API** is a project developed with Ruby on Rails that offers endpoints for merchants, users and transactions 

---

## Características

- **API RESTful:** Built following the best practices of Ruby on Rails.
- **Documentation:** Uses Swagger to display API documentation.
- **Tests:** Integrated with RSpec to ensure code quality.

---

## Technologies

- **Backend:** Ruby (3.3.7) and Ruby on Rails (8.0.2)
- **Containers:** Docker & Docker Compose
- **Documentation:** Swagger (rswag-api, rswag-ui, rswag-specs)
- **Tests:** RSpec
- **Database:** PostgreSQL

---

## Installation

### Previous Requirements

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [VS Code](https://code.visualstudio.com/) or any other IDE

### Steps to Configure this Repo Locally

1. **Clone the repository:**
   ```bash
   git clone https://github.com/anderCM/Tod.git
   cd Tod

2. Set up your own `.env` file or use `.env.example`
3. Run:
    ```
    docker-compose build
    docker-compose up -d

4. Install necessary gems using one of these options:
  - **4.1** From your local environment: `docker-compose run api bundle install`
  - **4.2** By connecting to the container:
      ```
      docker-compose exec api bash
      bundle install
5. Create the DB using one of these options:
  - **4.1** From your local environment: `docker-compose run api rails db:create`
  - **4.2** By connecting to the container:
      ```
      docker-compose exec api bash
      rails db:create
      rails db:seed

6. Visit http://localhost:3000 or use any PORT you configured in `.env` file