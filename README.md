# paperclip-sample
Rails 4 paperclip usage example has record with multiple image attachments

## The environment

We use [rbenv](https://github.com/sstephenson/rbenv) and current Ruby, 
`ruby 2.1.5p273 (2014-11-13 revision 48405) [x86_64-darwin13.0]`
(on a Mac OS X Yosemite Version 10.10.4, yes, we're spoiled).

We also use [RubyGems](https://rubygems.org) at version 2.4.8 and 
[Bundler](http://bundler.io/v1.9/)
at version 1.9.9 to avoid the dreaded "BUNDLED WITH" virus.
We hope someone soon succeeds in knocking some sense
into the people who added BUNDLED WITH to Bundler and have that removed.
(Several have tried.)
Until then, or until we give up, `gem install bundler -v 1.9.9`

We're used to [RSpec](http://www.rubydoc.info/gems/rspec-rails/frames).
We have nothing to say against MiniTest.
The RSpec people seduced us and that's the world we know.
The Gemfile.lock shows the version in use.
```
rails new -T paperclip-sample
cd paperclip-sample
rails generate rspec:install
```

We're not using RDoc, either.  But perhaps we ought to.

Note that before we write a line of code we have sixty Gemfile
dependencies, plus Rubygems, Bundler, and Ruby itself.
And that's just the ship, riding on the ocean.
We stand on the shoulders of giants.

Many thanks to [Thoughtbot](https://thoughtbot.com/) 
for the [PaperClip](https://github.com/thoughtbot/paperclip) gem,
and their [many other contributions](https://github.com/thoughtbot)
to Rails and open source.


## Procedure

We start by bootstrapping a Rails 4 app according to
[Getting Started With Rails](http://guides.rubyonrails.org/getting_started.html)
Find the version in use documented in the Gemfile.

The tag, '[hello-rails](https://github.com/telegraphy-interactive/paperclip-sample/tree/hello-rails)'
has the basic Rails installation with the hello page.
This is the state of the code base after Section 4 of the getting started guide.

The tag, '[articles-crud](https://github.com/telegraphy-interactive/paperclip-sample/tree/articles-crud)'
has the Articles CRUD application developed in Section 5
of the guide.
We followed it pretty closely, only:
- we used a fancy `:title` content helper.
- we didn't use tables

The tag, '[one-to-many](https://github.com/telegraphy-interactive/paperclip-sample/tree/one-to-many)'
has the comment model developed in Sections 6, 7 and 8.
We put the comment form ahead of the list of comments on the article show view.
As a consequence, the comments list always has the blank comment built,
but not saved, by the comment form.
That looks ugly.  It's especially troublesome when you try interacting
with the delete link for that "phantom" comment.  Ugh.  Not pretty.


### Embedded Form for Aggregated Content

We have an aggregate relation from Article to Comment.  A single article can aggregate many comments.
We have a form on an article that edits a new comment.
In this case, we're happy to add one comment to the article, and have the form fields for that
one comment be present from inception.  We don't need any button or link to add dynamically an
arbitrary number of comments.

We follow the methods taught by:
- [API Doc' for ActiveRecord::NestedAttributes](http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html)
- [API Doc' for fields_for](http://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-fields_for)

(These little gems hide away in the RDoc's for Rails.  Shine a little light on them.)

First we add this line into the Article model, `app/models/article.rb`:
```
 accepts_nested_attributes_for :comments, :reject_if => :all_blank, allow_destroy: true
```
The nested attributes method adds dynamic update, insert, and destroy of the dependent comment records,
through params, when updating or creating an article.

For the Comment model, `app/models/comment.rb` we add a validation:
```
  validates_presence_of :article
```
Prevents us saving a comment without an aggregating article.

#### Testing entry of a comment

We need a test, of course.  It's that or do a lot of trial-and-error clicking through the UI.
And the automated test can be run over and over.  Bonus.  With the test environment
set up, we add `spec/features/article_comment_spec.rb` with:
```
RSpec::describe Article do
  before :example do
    article = Article.create(title: Forgery(:lorem_ipsum).sentences, text: Forgery(:lorem_ipsum).text)
    visit article_path(article.id)
  end

  it 'shows no comments when there are none' do
    expect { 
      find(:xpath, '//h2[text()="Comments"]') 
    }.to raise_error(Capybara::ElementNotFound)
  end

  it 'accepts and displays a new comment' do
    commenter = Forgery(:name).first_name
    fill_in 'Commenter', :with => commenter
    fill_in 'Body', :with => Forgery(:lorem_ipsum).sentences
    click_button('Save comment')
    expect {
      find(:xpath, '//h2[text()="Comments"]')
    }.to_not raise_error(Capybara::ElementNotFound)
    expect {
      find(:xpath, "//div/p[starts_with(text(),'#{commenter} says,']")
    }.to_not raise_error(Capybara::ElementNotFound)
  end
end
```

This commit [2dfeaae](https://github.com/telegraphy-interactive/paperclip-sample/commit/2dfeaae128485ba891566a9a502212fac0bd688d)
has the test environment setup.

#### Enabling the form and controller though nested attributes

Inside the article view that shows the article, we have the form that adds a comment.
How can we use `fields_for` to arrange the form input elements such that the
params of the POST come through in a way that makes sense to `accepts_nested_attributes_for`?
We try it.  Study the `name` attributes on the input fields, study the params that
come through to the controller on submit.  A bit of trial and error brings us to
this setup on the form, `app/views/comments/_form.html.erb`:
```
<%= form_for @article do |article_form| %>
  <%= article_form.fields_for(:comments, Comment.new) do |comment_fields| %>
    <p>
      <%= comment_fields.label :commenter %><br>
      <%= comment_fields.text_field :commenter %>
    </p>
    <p>
      <%= comment_fields.label :body %><br>
      <%= comment_fields.text_area :body %>
    </p>
  <% end %>
  <p>
    <%= article_form.submit 'Save comment' %>
  </p>
<% end %>
```
When we succeed, the test log shows,
```
Started PATCH "/articles/1" for 127.0.0.1 at 2015-07-18 16:19:53 -0600
Processing by ArticlesController#update as HTML
Parameters: {"utf8"=>"✓", "article"=>{"comments_attributes"=>{"0"=>{"commenter"=>"Ernest", "body"=>"Lorem ipsum dolor sit amet, consectetuer adipiscing elit."}}}, "commit"=>"Save comment", "id"=>"1"}
Article Load (0.2ms)  SELECT  "articles".* FROM "articles" WHERE "articles"."id" = ? LIMIT 1  [["id", 1]]
(0.1ms)  SAVEPOINT active_record_1
Article Load (0.1ms)  SELECT  "articles".* FROM "articles" WHERE "articles"."id" = ? LIMIT 1  [["id", 1]]
SQL (2.3ms)  INSERT INTO "comments" ("commenter", "body", "article_id", "created_at", "updated_at") VALUES (?, ?, ?, ?, ?)  [["commenter", "Ernest"], ["body", "Lorem ipsum dolor sit amet, consectetuer adipiscing elit."], ["article_id", 1], ["created_at", "2015-07-18 22:19:53.531694"], ["updated_at", "2015-07-18 22:19:53.531694"]]
```
The HTML content of the form looks like,
```
<form class="edit_article" id="edit_article_1" action="/articles/1" accept-charset="UTF-8" method="post"><input name="utf8" type="hidden" value="&#x2713;" /><input type="hidden" name="_method" value="patch" />
  
  <p>
    <label for="article_comments_attributes_0_commenter">Commenter</label><br>
    <input type="text" name="article[comments_attributes][0][commenter]" id="article_comments_attributes_0_commenter" />
  </p>
  <p>
    <label for="article_comments_attributes_0_body">Body</label><br>
    <textarea name="article[comments_attributes][0][body]" id="article_comments_attributes_0_body">
</textarea>
  </p>
  <p>
    <input type="submit" name="commit" value="Save comment" />
  </p>
</form>
```

The differences on commit,
[e2903f3](https://github.com/telegraphy-interactive/paperclip-sample/commit/e2903f31ddfc1f76a35a625dbb5a5304d774206b)
show the necessary changes.

#### Wrap on adding comments to an article

This repairs a shortcut taken by the Getting Started Guide regarding the comment
form embedded in the view that shows an article.
The tag, 'embedded-comments' snapshots the application at this point.
It seems orthogonal to our task of adding image attachments, like a distraction,
but hang in there.  We'll do something like this again.

Now we'll get to the meat, on task.
We'll use PaperClip to attach an image to an article.


### Add an image attachment to an article

We'll just add one image on a one to many model with Article. 
This is warm-up for adding multiple images.


### Add multiple images to an article
Now we need a button to create new forms to 
- [Nested Model Form Railscast Part 1](http://railscasts.com/episodes/196-nested-model-form-part-1?view=asciicast)
- [Nested Model Form Railscast Part 2](http://railscasts.com/episodes/197-nested-model-form-part-2?view=asciicast)
- [Dynamic forms Railscast (requires subsription)](http://railscasts.com/episodes/403-dynamic-forms?view=asciicast)

## A note about the license

This is on a Creative Commons "CC0 1.0 Universal" license so you can copy, 
paste and modify any part of this code without attribution.  
That seems reasonable for sample code that
most would use in precisely that way.

However, taking a wholesale copy and representing it as your own work would be
reprehensible.  Few people pay respect to a person who has done such a thing.

If you like, you can provide attribution with a reference to this project, e.g.
"Learned from telegraphy-interactive/paperclip-sample on GitHub,
https://github.com/telegraphy-interactive/paperclip-sample"

## Editor's guide from Rails

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

