---
{
    "title": "Switching Between Multiple AWS Accounts",
    "description": "How to set up switch role permissions in AWS to easily move between accounts",
    "image": "v1629197724/jerrys_drkizx.png",
    "published": "2020-03-04",
}
---
Whether you use AWS across your organisation or for personal projects, it is useful to set up multiple accounts on 
AWS to separate your staging/test and production environments.

Separating your development and production accounts allows you to experiment in a real cloud environment without 
negatively impacting your production environment. It also stops staging and development environments from consuming 
service limit capacity for your production resources.

The naive way of doing this involves constantly logging out and back in each time you want to change accounts or 
setting up multiple chrome profiles that save your credentials for each account.

A better way is to leverage assumed roles via IAM permissions and Organisation Units.


### AWS Organisations

Under your root AWS account, create an organisational unit. You can access the Organizations page by clicking on 
your account dropdown in the top right-hand corner of the web console.

![AWS console — Navigate to My Organisation](https://cdn-images-1.medium.com/max/5312/1*wotQ528ngauzVHzx9LVP8g.png)

Once in the Organization view, create your desired organisation units. Below I've created Production, Staging and 
Playground accounts. Production and Staging are generally fine for most companies. I use "Playground" as a place to 
try new AWS products in an environment I know I can safely nuke anything at any time.

![AWS Console — Organisation Unit View](https://cdn-images-1.medium.com/max/4084/1*5kjJHMDp6to2vbwduQOuFg.png)

**Note:** All the accounts we are about to create all get billed in your root account.

Once we have created these organizsational units, we are going to need to add user accounts to them. Under Accounts, 
we are going to create some new accounts

![AWS Console — Create Account View](https://cdn-images-1.medium.com/max/4148/1*-kgPDyVEvA7-hF-jN4kr0Q.png)

The AWS account name I generally name after the organisational unit to keep things clear. The email I will usually 
do something like *michael+<environment>@domain.com.* 

Leave the IAM role name as the default *OrganizationAccountAccessRole *(this is important).

**Note:** AWS requires unique emails, so adding the “+pod” etc will satisfy that requirement while still delivering 
emails to your primary domain.

Once you create these users, you’ll need to wait 1–5 minutes for an invitation email from AWS. You’ll then need to 
use the *forgot password* functionality to set a password for these accounts. I suggest using a password manager and 
making these strong.

Log in to each of these accounts and note down the Account Number of each one. You’ll need these in a later step.

### Create an IAM User

Once we have the root accounts for production and staging, we need to create a user that can easily hop between 
these accounts. Unfortunately (and for reasons that aren’t clear to me) root accounts can not hop between other root 
accounts. We’ll need to create a dedicated IAM user and then give them access to all the accounts we created (root, 
production, staging etc).

![AWS Console — Create IAM user](https://cdn-images-1.medium.com/max/4196/1*H4xsRc4e1HMGp2BZ38Txzw.png)

We give this user a username and give them access to the AWS management console. It’s important that we don’t give 
programmatic access here — if we need programmatic access to these accounts (for deployments via CLI etc, we will 
use the root credentials or create new ones). This user is merely for hopping between the AWS console across your 
accounts.

![AWS Console — IAM user permissions](https://cdn-images-1.medium.com/max/4276/1*wJR-Qqz0VMXrmkZgdy6BqA.png)

I'll give this user administration permissions as I am the admin and want to use this user across all my accounts. 
If you are creating a user for someone else in your organisation you may want to change the access policies as needed.

### Switch Roles

Once you create this user you will be given a special login link. Click through to this link and then log in as this 
user. Once you log in you should see that the main account menu gives you access to a new option called Switch Role.

![AWS Console — IAM user login with Switch Role](https://cdn-images-1.medium.com/max/5888/1*F-wTXK0vdWEAC1-Xl6A94A.png)

![AWS Console- Switch Role](https://cdn-images-1.medium.com/max/5448/1*2PguwsfVzk9tbpfQlnBuYw.png)

The *Switch Role* screen will prompt you to input the account number of the account you want to switch to. Add the 
account number of the Staging/Production account we created earlier.

In the *Role* section, we need to input the role name we created with those accounts *OrganizationAccountAccessRole.* 
Then give the account display name and a colour and hit the Switch Role button.

This will save this role on your account and redirect you to it. You can repeat this step with any other accounts 
you want to be able to hop between.

![AWS Console — Switch Roles](https://cdn-images-1.medium.com/max/6096/1*oZWSJSLsNPz7f4NixoMywQ.png)

You’ll now be able to switch between accounts at the click of a button. Once you switch to an account you’ll clearly 
be able to see which account you are in.

![AWS Console — Example Production Account](https://cdn-images-1.medium.com/max/6136/1*EU2suiGDh9GABTqCEWH7yA.png)

Now as a solo developer you’ll be able to sandbox your environments, have clean accounts to play with new 
technologies, and not have to worry about deleting resources or experimenting and breaking production code.

At an organisation level, you will be able to create separate root accounts for various parts of your organisation 
and give users access to only the environments they need.
