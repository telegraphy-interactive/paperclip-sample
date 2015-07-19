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


### Improving the form for adding article comments

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

The second key is the controller, which must allow the nested attributes for assignment,
`app/controllers/articles_controller.rb`:
```
class ArticlesController < ApplicationController

# .... controller methods omitted

private

  def article_params
    params.require(:article).permit(
        :title, :text, comments_attributes: [ :commenter, :body ] )
  end

end
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

We'll add an Attachment model that has 
one image and a many to one model with Article. 
One Article has many Attachments.
We'll do one attachment as warm-up for adding multiple images.

We follow the installation and getting started instructions from Thoughtbot at
[Paperclip](https://github.com/thoughtbot/paperclip#installation).
Add the gem to the gemfile and `bundle install`.
```
# attachments
gem 'paperclip', '~> 4.3'
```
The 4.3 version of Paperclip has improved checking of the uploaded file
to ensure that it is an image type of thing (as opposed to mean attacking
your web site kind of thing).

Rather than adding the image directly to the Article model, we add it to a new model,
Attachment.  We generate a migration for the new model with:
```
rails generate model attachment article:references caption:string image:attachment
```
The attachment type comes from Paperclip.

Here is the migration, `db/migrate/20150719005637_create_attachments.rb`:

```
class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.integer :article_id, null: false
      t.string :caption
      t.attachment :image

      t.timestamps null: false
    end
  end
end
```

And we need a test.  The test visits the new article page, attaches an image,
submits, and checks to see the image present on the article show view.
We also include a test for adding an image to an existing article.
`spec/features/article_picture_spec.rb`:
```
RSpec::describe Article do

  def valid_image_name
    'valid_image.jpg'
  end

  def fill_in_image_form_fields
    image_file_name = File.join(File.absolute_path('..', File.dirname(__FILE__)), 'resources', valid_image_name)
    attach_file 'article_attachments_attributes_0_image', image_file_name
    fill_in 'Caption', with: Forgery(:lorem_ipsum).title
  end

  it 'new article accepts an image attachment' do
    visit new_article_path
    fill_in 'Title', with: Forgery(:lorem_ipsum).title
    fill_in 'Text', with: Forgery(:lorem_ipsum).sentences
    fill_in_image_form_fields
    click_button('Create Article')
    image = find('img')
    expect(image[:src]).to have_content(valid_image_name)
  end

  context 'existing article without picture' do
    before :example do
      @article = Article.create(title: Forgery(:lorem_ipsum).title, text: Forgery(:lorem_ipsum).sentences)
    end

    it 'shows no picture on view' do
      visit article_path(@article.id)
      expect { 
        find('img') 
      }.to raise_error(Capybara::ElementNotFound)
    end

    it 'accepts and displays an image on edit' do
      visit edit_article_path(@article.id)
      fill_in_image_form_fields
      click_button('Update Article')
      image = find('img')
      expect(image[:src]).to have_content(valid_image_name)
    end
  end
end
```

The Article model now has many attachments.  We also want to edit the
attributes for the attachments when editing the article model.
We set that up by adding these two lines to the Article model file,
`app/models/article.rb`:
```
  has_many :attachments, :dependent => :destroy
  accepts_nested_attributes_for :attachments, :reject_if => :all_blank, allow_destroy: true
```

In the good old days we would have added the parameters allowed
for assignment to the model right there in the model.
Now the opinion coded into Rails is that this setting belongs in
the controller.  A downside is making two places to specify the
nested attributes behavior.  The upside is that the controller has
control over POST/PUT/PATCH params.

The articles controller must now allow the nested attributes for the
attachment.  We modified the `article_params` method of 
`app/controllers/articles_controller.rb` as follows:
```
   def article_params
     params.require(:article).permit(
         :title, :text,
         comments_attributes: [ :commenter, :body ],
         attachments_attributes: [ :image, :caption ]
     )
   end
```
The `attachments_attributes: [ :image, :caption ]` line is new.

The Attachments model file, `app/models/attachment.rb` specifies a 
`belongs_to` relationship with Article.  It has the two methods
needed to set-up Paperclip attachment behavior on the image attribute.
```
class Attachment < ActiveRecord::Base
  belongs_to :article

  has_attached_file :image, :styles => { :large => "1024x1024", :medium => "300x300>", :thumb => "100x100>" }

  validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
end
```

The form for editing an article, `app/views/articles/_form.html.erb`
must now indicate that the data in a POST or PATCH will be "multi-part."
It will contain normal params data along with binary data read from a
file, encoded, and forwarded by the browser.  The `form_for` method
now looks like this:
```
<%= form_for @article, :html => { :multipart => true } do |f| %>
```

Later in the file we add the fields for adding an attachment,
```
  <%= f.fields_for(:attachments, Attachment.new) do |attachment_fields| %>
    <p>
      <%= attachment_fields.label :image %><br>
      <%= attachment_fields.file_field :image %>
    </p>
    <p>
      <%= attachment_fields.label :caption %><br>
      <%= attachment_fields.text_field :caption %>
    </p>
  <% end %>
```

In the view for showing an article,
`app/views/articles/show.html.erb`,
we add a line for displaying the attachments:
```
<%= render @article.attachments %>
```

That implies a new view for showing each attachment.
The place for that file, such that it "Just Works" is,
`app/views/attachments/_attachment.html.erb`, and here is its
content:
```
<p><%= image_tag attachment.image.url(:medium) %></p>
```
Paperclip takes care of the image attribute methods, all of the scaling,
and the delivery of that url to a medium sized image on our server.

There are a lot of details yet undeveloped:
- We can't remove the image.
- We can't change the image, in fact...
- When we edit an article, the image file selector attaches
a new image to the article.

The commit that effected the image attachments is 
[cc204ff](https://github.com/telegraphy-interactive/paperclip-sample/commit/cc204fff0823d8ca246c863446c55e8096199f97).
We tagged the project here with 'one-attachment-to-article'.

This multiple image behavior is actually behavior we want; so, we're going to roll on with it,
rather than work to "correct" it.

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

