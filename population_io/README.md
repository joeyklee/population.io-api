population_io
=============

Django project for population.io

## Requirements

* Python 2.7
* pip 1.5+
* further dependencies can be installed with pip from a requirements file

## Project setup for development

```shell
# Create a virtualenv to isolate our package dependencies locally
virtualenv env
source env/bin/activate  # On Windows use `env\Scripts\activate`

# Install dependencies
pip install --requirement requirements.txt

# Run development server
python manage.py runserver
```

## Deploy to Heroku

* Set up Heroku account, install the Heroku toolbelt and login. See: https://devcenter.heroku.com/articles/quickstart.
* Run `heroku create`, note the URL of your new app and the Heroku git repo.
* If Heroku didn't create a git remote for you, run `git remote add heroku <git_repo_url>`.
* Run `git subtree push --prefix population_io heroku master` to deploy to Heroku and run your app.
* View the API docs of your app at http://<heroku_app_name>.heroku.com/api/docs/.
