# PgJbuilder

PgJbuilder provides a wrapper around PostgreSQL's JSON functions ([array_to_json and row_to_json](http://www.postgresql.org/docs/9.3/static/functions-json.html)) allowing you to write queries that serialize their results directly to a JSON string. This completely bypasses creating ActiveRecord objects and using Arel giving a large speed boost. It is especially useful for creating JSON APIs with low response times.

## Benefits

Using PostgreSQL to serialize your query results to JSON is much
faster than serializing the records inside of Ruby.

## Installation

Add to your Gemfile:

    gem 'pg_jbuilder'

And then execute:

    $ bundle

## Requirements

PgJbuilder requires:

- PostgreSQL 9.2+
- ActiveRecord 3.0+

Compatible with Rails 3.0+

## Initializing the gem in a non-Rails environment

If you're using Rails you don't need to do any additional setup. To use
the gem outside of Rails there are a few things you need to do:

1. Set the database connection. This needs to be an ActiveRecord connection.

       PgJbuilder.connection = ActiveRecord::Base.connection
  This can also be a lambda{} that when called returns a connection.

2. Set the path where your queries will be. For example if your queries are in the app/queries directory:

       PgJbuilder.paths.unshift File.join(File.dirname(__FILE__),'app','queries')

3. The examples below are for Rails. For non-Rails applications where
   the examples below use `select_object` and `select_array` you can use
`PgJbuilder.render_object`, `PbJbuilder.render_array`,
`PgJbuilder.render` to render your
queries. Once rendered they can be sent to your database and will return
a single string of JSON. For example:

  ```ruby
  def user_json id
    sql = PgJbuilder.render_object 'users/show', id: id
    ActiveRecord::Base.connection.select_value(sql)
  end
  ```

## Usage

For Rails applications queries are expected to be in `app/queries`. You can change this
by creating an initializer and adding a different path to `PgJbuilder.paths` (see the example in Initializing the gem in a non-Rails environment).

### Returning a simple object:

1. Create a query that will select the columns you want to return in your JSON. For example to return a User as json you might create a query called `app/queries/users/show.sql`:

  ```sql
  SELECT
     users.id,
     users.email,
     users.first_name,
     users.last_name
  FROM users
  WHERE id = {{id}}
  ORDER BY id ASC
  ```

2. Add a method to your model that will render the JSON. For the user
     example you would add this to app/models/user.rb

  ```ruby
  class User < ActiveRecord::Base
     def show_json
       select_object 'users/show', id: id
     end
  end
  ```

  Note that queries use Handlebars for templating. We pass in the id to
  `select_object` then the `{{id}}` in the template will be replaced
  with this value. Read more on Handlebars syntax [on their
  website](http://handlebarsjs.com/expressions.html).

  This query would return a JSON object like:
  ```json
  {
     "id": 1,
     "email": "mbolton@initech.com",
     "first_name": "Michael",
     "last_name": "Bolton"
  }
  ```

  Since this is a JSON object and not an array the query must return
  only a single row. If more than one row is returned by the query
  PostgreSQL will raise an error and the query will fail.

3. Call the `show_json` method added to `User` to return the user as
     JSON. For example if you were using this in a JSON API then in your controller you might use:

  ```ruby
  class UsersController < ApplicationController
     before_filter :load_user
    
     def show
       render json: @user.show_json
     end

     private

     def load_user
       @user = User.find(params[:id])
     end
  end
  ```

### Returning a simple array

1. Create a query that will return all the rows and columns you want
     in your JSON. For example if you want to return a list of users we
  would create a query in `app/queries/users/index.sql` like this:

  ```sql
  SELECT
     users.id,
     users.email,
     users.first_name,
     users.last_name
  FROM users
  ORDER BY id
  ```

2. Add a method to your `User` model that renders the array:

  ```ruby
  class User < ActiveRecord::Base
     def self.index_json
       select_array 'users/index'
     end
  end
  ```

  This would return a JSON array like this:

  ```json
  [
     {
       "id": 1,
       "email": "mbolton@initech.com",
       "first_name": "Michael",
       "last_name": "Bolton"
     },
     {
       "id": 2,
       "email": "pgibbons@initech.com",
       "first_name": "Peter",
       "last_name": "Gibbons"
     },
     {
       "id": 3,
       "email": "snagheenanajar@initech.com",
       "first_name": "Samir",
       "last_name": "Nagheenanajar"
     }
  ]
  ```

3. Call the method added to the `User` model to return the JSON. For
   example in your controller you might add:

  ```ruby
  class UsersController < ApplicationController
     def index
       render json: User.index_json
     end
  end
  ```

### Quoting/Escaping values

You can use the `{{quote}}` helper to escape user inputted values to
make them safe to include in the query. For example if your query is
`app/queries/users/search.sql`:

```sql
SELECT users.id
FROM users
WHERE
  users.first_name = {{quote first_name}}
```

and you call the query:
```ruby
select_array 'users/search', first_name: 'John'
```

it will render the query as:
```sql
SELECT users.id
FROM users
WHERE
  users.first_name = 'John'
```

Without the quote helper it would render as:

```sql
SELECT users.id
FROM users
WHERE
  users.first_name = John
```

without the quotes which would allow SQL injection attacks. `{{quote}}`
will also escape quotes for example:

```ruby
select_array 'users/search', first_name: "Jo'hn"
```

will render as:
```sql
SELECT users.id
FROM users
WHERE
  users.first_name = 'Jo''hn'
```

### Partials

You can include partials in your template using the `{{include}}`
helper. For example you might refactor the SELECT portion of your query
into its own partial `app/queries/users/select.sql`

```sql
SELECT
  users.id,
  users.first_name,
  users.last_name,
  users.email
```

Then in `app/queries/users/show.sql` you would have:

```sql
{{include 'users/select'}}
FROM users
WHERE id = {{id}}
```

Variables passed into a query will automatically be passed into the
partial. In the above example there is a `{{id}}` variable. You would
also be able to use this variable in the partial.

You can pass additional variables into the partial using this syntax:

`{{include 'template_name' variable1='value' variable2='value' ...}}`

### Embedding objects and arrays

#### Objects

You can embed objects using the `{{object}}` helper. For example if you
want to have a user object inside a your comment index in
`app/queries/comments/index.sql`:

```sql
SELECT
  comments.id,
  comments.body,
  {{#object}}
    SELECT
      users.id,
      users.first_name,
      users.last_name,
      users.email
    FROM users
    WHERE
      users.id = comments.user_id
  {{/object}} AS user
FROM comments
ORDER BY id
```

This would create a JSON object like:
```json
{
  "id": 1,
  "body": "This is my comment",
  "user": {
    "id": 100,
    "username": "witty_commenter"
  }
}
```

You can also refactor the object into a partial. So you could create a
query in `app/queries/users/object.sql`:

```sql
SELECT
  users.id,
  users.first_name,
  users.last_name,
  users.email
FROM users
WHERE
  users.id = {{id}}
```

Then include it using this syntax in `app/queries/comments/index.sql`:

```sql
SELECT
  comments.id,
  comments.body,
  {{object 'users/object' id='comments.user_id'}} AS user
FROM comments
ORDER BY id
```

This would produce the same JSON as above.

#### Arrays

Embedding arrays works just like embedding objects but uses the
`{{array}}` helper. For example if you have a user object in
`app/queries/users/show.sql` and want to return a list of the user's
comments inside the user object:

```sql
SELECT
  users.id,
  users.first_name,
  users.last_name,
  users.email,
  {{#array}}
    SELECT
      comments.id,
      comments.body
    FROM comments
    WHERE comments.user_id = users.id
  {{/array}} AS comments
FROM users
WHERE id = {{id}}
```

This would return a JSON object like:

```json
{
  "id": 1,
  "username": "witty_commenter",
  "comments": [
    {
      "id": 100,
      "body": "Witty Comment #1"
    },
    {
      "id": 200,
      "body": "Witty Comment #2"
    }
  ]
}
```

Just like with `{{object}}` you can refactor your arrays into a partial.
So if you have `app/queries/users/comments.sql`

```sql
SELECT
  comments.id,
  comments.body
FROM comments
WHERE comments.user_id = {{user_id}}
```

then in `app/queries/users/show.sql` you can have:

```sql
SELECT
  users.id,
  users.username,
  {{array 'users/comments' user_id='users.id'}} AS comments
FROM users
WHERE id = {{id}}
```

### Pagination

To do pagination you need to execute two queries. One to count the rows,
then another to return the results with a LIMIT and OFFSET. To
accomplish this with pg_jbuilder your query would have to look like
this:

```sql
SELECT
  {{#if count}}
    COUNT(*) AS total_rows
  {{else}}
    comments.id,
    comments.body
  {{/if}}
FROM comments
{{#unless count}}
  ORDER BY id
  LIMIT {{per_page}}
  OFFSET ({{quote page}} - 1) * {{per_page}}
{{/unless}}
```

Then in your model:
```ruby
class Comment < ActiveRecord::Base
  PER_PAGE = 20
  def self.count_index_json attrs={}
    attrs[:count] = true
    attrs[:per_page] = PER_PAGE
    select_value('comments/index').to_i
  end

  def self.index_json attrs={}
    attrs[:per_page] = PER_PAGE
    select_array 'comments/index', attrs
  end
end
```

`select_value` will return render your query and return a single value
from it.

And in your controller:
```ruby
class CommentsController < ApplicationController
  def index
    count = Comment.count_index_json(index_params)
    headers['X-Pagination-Total-Entries'] = count.to_s
    render json: Comment.index_json(index_params)
  end

  private

  def index_params
    params.permit :page
  end
end
```

The API consumer can then read the `X-Pagination-Total-Entries` to see the
total number of entries and can pass a `page` parameter to specify which
page to fetch.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/pg-json/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
