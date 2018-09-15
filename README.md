# Deprecated

[Paperclip](https://github.com/thoughtbot/paperclip)
has deprecated itself and as such this sample project is likewise deprecated.
Paperclip recommends
[ActiveStorage](http://guides.rubyonrails.org/active_storage_overview.html)
as its replacement. Perhaps one day we'll revive this, rename it, and use it
as an exercise in migrating to ActiveStorage.

For now, please don't use this. It has security vulnerabilites in gem
dependencies that are not repaired.

# paperclip-sample
Rails 4 application with
[Paperclip](https://github.com/thoughtbot/paperclip)
demonstrates viewing and editing a record with multiple image attachments.

[The Procedure](#procedure)
describes in some detail the steps followed 
to create this application.  That includes sections about:
- [Using nested attributes](#improving-the-form-for-adding-article-comments)
to edit a model together with 
attributes of some of its associated records within a single form.
- [Attaching an image](#add-an-image-attachment-to-an-article) using Paperclip
- [Attaching images](#add-multiple-images-to-an-article) on multiple associated records


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
for the [Paperclip](https://github.com/thoughtbot/paperclip) gem,
and their [many other contributions](https://github.com/thoughtbot)
to Rails and open source.


## Trying this out

Assuming you have Git, Ruby, RubyGems, and Bundler installed and working on your system
(Yes, that's a lot; but, you have to get that far):

* clone this repository with the command, 
`git clone git@github.com:telegraphy-interactive/paperclip-sample.git`
* change to the directory, `cd paperclip-sample`
* install the dependencies with the command, `bundle install`
* serve the application on your computer with the command, `rails server`
* steer a web browser on your computer to [http://localhost:3000](http://localhost:3000)


## The Procedure

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
    assert_selector(:xpath, '//h2[text()="Comments"]')
    assert_selector(:xpath, "//div/p[starts-with(text(),'#{commenter} says,')]")
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
We'll use Paperclip to attach an image to an article.


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

The HTML form rendered for editing a new article looks like this:
```
<form class="new_article" id="new_article" enctype="multipart/form-data" action="/articles" accept-charset="UTF-8" method="post"><input name="utf8" type="hidden" value="&#x2713;" /><input type="hidden" name="authenticity_token" value="hTpzNtxi0Ki5pUX2HpWOob20BnRm3FgfHLpBX7PAJft7Xlqz6CwEvvTezQ54P851/KJmEAQo+3RsPi4HCBUPng==" />
  <p>
    <label for="article_title">Title</label><br>
    <input type="text" name="article[title]" id="article_title" />
  </p>
 
  <p>
    <label for="article_text">Text</label><br>
    <textarea name="article[text]" id="article_text">
</textarea>
  </p>
  
    <p>
      <label for="article_attachments_attributes_0_image">Image</label><br>
      <input type="file" name="article[attachments_attributes][0][image]" id="article_attachments_attributes_0_image" />
    </p>
    <p>
      <label for="article_attachments_attributes_0_caption">Caption</label><br>
      <input type="text" name="article[attachments_attributes][0][caption]" id="article_attachments_attributes_0_caption" />
    </p>

  <p>
    <input type="submit" name="commit" value="Create Article" />
  </p>
</form>
```

The POST for a new article with image attachment looks like this (we've added some formatting):
```
Started POST "/articles" for 127.0.0.1 at 2015-07-19 16:36:04 -0600
Processing by ArticlesController#create as HTML
  Parameters: {
    "utf8"=>"✓", 
    "article"=>{
      "title"=>"Lorem Ipsum Dolor Sit Amet, Consectetuer Adipiscing Elit", 
        "text"=>"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin risus.", 
        "attachments_attributes"=>{
          "0"=>{
            "image"=>#<ActionDispatch::Http::UploadedFile:0x007face9bcd020 
            @tempfile=#<Tempfile:/var/folders/x0/nv0zmnk52w36xdmngpj9y3240000gn/T/RackMultipart20150719-24623-1jkt1ql.jpg>, 
            @original_filename="valid_image.jpg", @content_type="image/jpeg", 
            @headers="Content-Disposition: form-data; name=\"article[attachments_attributes][0][image]\"; 
              filename=\"valid_image.jpg\"\r\nContent-Type: image/jpeg\r\nContent-Length: 50021\r\n">, 
            "caption"=>"Lorem Ipsum Dolor Sit Amet, Consectetuer Adipiscing Elit"
          }
        }
      },
    "commit"=>"Create Article"
  }
```

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

From the prior section, "Add an image attachment to an article" we gained Paperclip
and a model for adding attachments.  We have an Article model in a one-to-many relationship
with an Attachment model.  The Attachment model has an `image` attribute managed by Paperclip,
together with a `caption` attribute managed by us.

We add some tests to the article attachments `spec/features/article_picture_spec.rb` for the new behavior:
- to add multiple images when editing the article
- to view all of the images
- to delete any or all of the images when editing the article

#### Testing

The RSpec source for testing the image attachments is getting quite long.
You can find it at [spec/features/article_picture_spec.rb](https://github.com/telegraphy-interactive/paperclip-sample/blob/master/spec/features/article_picture_spec.rb).
Here is one of the add image tests:
```
  it 'new article accepts multiple image attachments' do
    start_a_new_article
    add_image_to_article
    second_image_name = 'second_image.png'
    add_image_to_article(second_image_name)
    click_button('Create Article')
    assert_selector('img', count: 2)
    images = all('img')
    expect(images[0][:src]).to have_content(valid_image_name)
    expect(images[1][:src]).to have_content(second_image_name)
  end
```
Some say not to upload images during test, but rather to mock create the objects that contain
image attachments.  The argument is for speed, we suppose.
We're not having a problem with speed.  The images are small in any case.
Further, if we don't test the uploads and deletions completely through the UI, then we've added
a manual task of testing before release; or else, we're testing in production.

#### Strategy

The `fields_for` code we have placed in the article edit form, `app/views/articles/edit.html.erb`
is just what we need to add or edit an attachment.  The trick now is that we need zero or more
instances of that code operating on newly created and existing attachments.

We're going to resort to using some unobtrusive JavaScript.  We'll attach the script to a button
that inserts a new copy of the attachment form whenever we press it.
Using the button will enable adding an arbitrary number of image attachments to an article
when editing the article.
This strategy is taught in a couple of Ryan Bates' Rails screencasts:
- [Nested Model Form Railscast Part 1](http://railscasts.com/episodes/196-nested-model-form-part-1?view=asciicast)
- [Nested Model Form Railscast Part 2](http://railscasts.com/episodes/197-nested-model-form-part-2?view=asciicast)
- [Dynamic forms Railscast (requires subscription)](http://railscasts.com/episodes/403-dynamic-forms?view=asciicast)

#### Execution

Let's start at the high level with the form for creating and editing
articles.  The view code for that is, 
`app/views/articles/_form.html.erb` (We elide some of the error
processing code near the top.):
```
<% if @article.errors.any? %>
  ...
<% end %>

<%= form_for @article, :html => { :multipart => true } do |f| %>
  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>
  </p>
 
  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>

  <div id='attachments'>
    <%= render partial: 'attachment_edit', collection: @article.attachments, locals: { builder: f } %>
  </div>

  <%= link_to_add_fields('Add Image', f, 'attachments') %>

  <p>
    <%= f.submit %>
  </p>
<% end %>
```
The form has two important details:
- It renders the existing associated records within an enclosing
element, a `div`, with an `id` named with the name of the association.
- It uses a helper `link_to_add_fields` to render the
link that will grow the form with fields for a new associated record.

The form uses two partials, one to edit existing attachments, the
other to create new attachments.  The form renders 
fields for editing existing attachments with,
```
    <%= render partial: 'attachment_edit', collection: @article.attachments, locals: { builder: f } %>
```

Here is the content of the partial,
`app/views/articles/_attachment_edit.html.erb`
```
<fieldset>
  <%= builder.fields_for(:attachments, attachment_edit) do |f| %>
    <p><%= image_tag attachment_edit.image.url(:medium) %></p>
    <p>
      <%= f.label :caption %><br>
      <%= f.text_field :caption %>
    </p>
    <p>
      <%= f.hidden_field :_destroy %>
      <%= link_to 'Delete image', '#', class: 'remove_fields' %>
    </p>
  <% end %>
</fieldset>
```

The `render` method will invoke this attachment once for each member
of the many attachments already associated with the article.
The partial receives the ActiveRecord model object as variable,
`attachment_edit`, by convention, the name of the partial.

It proceeds to build the image tag, fields for editing the caption,
and a link to delete the record.  The call to `render` from
the form adds the content rendered by this partial directly, in-place
into the form.

There are some little tricks to note with this partial and its use:
- The `link_to 'Delete image' ...` near the bottom has a magic class,
`remove_fields`.  You'll see why.
- There's a hidden field with name, `_destroy` just before the
link to delete.
- The entire partial renders within a `fieldset` element, including
the link to delete.
The rest of the content is pretty much up to your need,
provided the partial satisfies those details.

The second partial used by the form is hidden away in the call
to `link_to_add_fields`.  We'll look at that call shortly, but first,
here is the content of the partial that will render.  It is the
partial inserted into the document to add a new associated record,
in this case, an attachment. By convention coded into the definition
of `link_to_add_fields`, it has name,
`app/views/articles/_attachment_fields.html.erb`:
```
<fieldset>
  <p>
    <%= f.label :image %><br>
    <%= f.file_field :image %>
  </p>
  <p>
    <%= f.label :caption %><br>
    <%= f.text_field :caption %>
  </p>
  <p>
    <%= f.hidden_field :_destroy %>
    <%= link_to 'Remove', '#', class: 'remove_fields' %>
  </p>
</fieldset>
```
This partial is so very similar to, and yet different than the
partial for editing existing associated records.  In some
applications the two would be the same.
Most importantly, it also satisfies three very important details:
- The `link_to 'Delete image' ...` near the bottom has a magic class,
`remove_fields`.
- There's a hidden field with name, `_destroy` just before the
link to delete.
- The entire partial renders within a `fieldset` element, including
the link to delete.

Those details are so important, we just told them to you twice.

So now we have looked at the visual elements that go into editing
existing and new associated records.  A big trick that we haven't
yet investigated is `link_to_add_fields`.

We need a link that renders form content into the document,
dynamically, when we activate it.  It more than a line of code
to accomplish that.  We place it in the view helper available
to all views in the application, `app/helpers/application_helper.rb`:
```
  def link_to_add_fields(name, f, association, button_class=nil, container_id=nil)
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize + "_fields", f: builder)
    end
    if container_id == nil
      container_id = association
    end
    container_id_css_spec = '#' + container_id
    opts = { class: 'add_fields', data: { id: id, container: container_id_css_spec, fields: fields.gsub("\n",'') } }
    if button_class != nil
      opts['class'] = "add_fields #{button_class}" 
    end
    link_to(name, '#', opts)
  end
```
The `name` parameter is the content of the link that will render
as a string, visible for clicking.  You see that the method passes
it along to the `link_to` call at the end.

The rest of the method is all about setting-up the `opts` for `link_to`.
In particular, the method sets up the `data: {container: }` option
that has new content rendered into the document.

The `f` parameter is the form builder enclosing the link. It is the `f`
from, `form_for ... do |f|`.

The `association` parameter is the name of the nested association on
the object of the enclosing form, `f`.  Take care to name the association
exactly. The name, `attachment` is not the right name to use if the
association is the plural, `attachments`.

Reading the code, you can see that it renders content using a
builder generated by `fields_for`.  This is so clever.  We're using
the Rails view render method to render new content for a Rails view.
Only we don't put that content into the document until the user
asks for it with a click.  So awesome.

More is needed, however.

The following coffescript carries out some trickery for the add
and delete links. Find it in the JavaScript assets as
`app/assets/javascripts/nested_forms.js.coffee`
```
jQuery ->
  $(document).on 'click', 'form .remove_fields', (event) ->
    $(this).prev('input[type=hidden]').val('1')
    $(this).closest('fieldset').hide()
    event.preventDefault()
  $(document).on 'click', 'form .add_fields', (event) ->
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $(this).before($(this).data('fields').replace(regexp, time))
    event.preventDefault()
```

The click event handler placed for removing fields does not really
remove them.  It hides them by hiding the enclosing `fieldset`.
It also finds the nearest hidden input field prior to itself in the
document, and sets the value on that field to `1`, or `true`.
We have arranged to have that hidden input field be the one for
`_destroy`  With `_destroy` set true, Rails will remove the
record on the PATCH call.

The click event handler placed for adding fields applies a regexp
to the content about to be added to the document.  The 
`link_to_add_fields` method coded a new object id into the
input fields.  This bit of JavaScript does little more than ensure
that new object id is unique, by replacing the hard-coded id
with a dynamic one based on the time.  The time is unique.
You would have to click pretty fast to foul this scheme!

We think we are done.  It's so exciting.  Yet it doesn't work.
The Rails protections for mass assignment foil us yet again.

Inside of the controller, `app/controllers/articles_controller.rb`,
we have to add permission for `_destroy` and `id` attributes
nested within the article params:
```
     params.require(:article).permit(
         :title, :text,
         comments_attributes: [ :commenter, :body ],
         attachments_attributes: [ :image, :caption, :_destroy, :id ]
     )
```
The clue to that was in the log output, where Rails told us that
it was not permitting them.

#### Recap

Here are the details to look after when setting up the dynamic
editing of an arbitrary number of members from a one-to-many
association nested within a form:

- A containing element named after the association.
- A partial (or two) to render forms for the associated records.
  - with the fields within a `fieldset`
  - with a hidden input field named, `_destroy`
  - with a delete link that has class, `remove_fields`
- A helper method that outputs an "add record" link
  - that renders the partial for the associated record into
  the `data-fields` attribute
  - that names the containing element in the `data-container`
  attribute
  - that sets the name of the placeholder for the new object id
  in the `data-id` attribute
- JavaScript methods that decorate the add and delete links
  - with code to hide the `fieldset` container and set the 
  value of the `_destroy` input field when delete activated.
  - with code to replace the placeholder id with a new, unique
  id within the data-fields rendered into the data-container.
- Properly enabled nested parameter mass assignment permissions,
  including the id.


#### Pitfalls

##### Turbolinks and JavaScript

Somewhere we picked up code that
places the on_click events for removing and adding
fields on new form elements as follows,
```
  $('form').on 'click', '.remove_fields', (event) ->
```
That worked great in test.  Poking around the browser we found that
the add and remove buttons worked only on first use after starting
the server.

What a puzzle!  Reading the Rails Guides section about working
with JavaScript we find this section about
[Turbolinks](http://guides.rubyonrails.org/working_with_javascript_in_rails.html#turbolinks),
with a suggestion about events that run against new pages.

Following the suggestion in the Rails Guide, we rewrote the 
coffescript for decorating the add and remove links as follows:
```
  $(document).on 'click', 'form .remove_fields', (event) ->
```
This change enabled the add and remove links to work as well in
development, and hopefully in production, as well as they did
in tests.

Looking back, we see now that the newer 
[Railscast episode #403](http://railscasts.com/episodes/403-dynamic-forms?view=asciicast)
does code these as `$(document).on 'click'`.
(That is an episode for which a subscription is needed.)

Turbolinks and asset pipeline do make it necessary to do some
smoke testing on a production-like server before deploying
much new code to production.

##### Test database

In the article_pictures feature spec you'll find a context and before
hook that set-up an existing article.
```
  context 'edit existing article' do
     before :example do
      start_a_new_article
      click_button('Create Article')
```
When we tried to use the ActiveRecord model to directly create an
article record, we ran into trouble with the tests.  The tests picked-up
a missing record exception from ActiveRecord when we tried to visit
the edit screen for the created model.  Therefore,
the original code as follows did not work:
```
  context 'edit existing article' do
     before :example do
      @article = Article.create(title: Forgery(:lorem_ipsum).title, text: Forgery(:lorem_ipsum).sentences)
```

This problem arose when we switched the Capybara driver from
the default, `rack_test` to `capybara_webkit`.  The same happened
when we tried `selenium-webdriver`.  We needed one of these for
the javascript support; so, we worked around it by driving the
article record creation through the application.

This is troubling.  If you know the cause, please speak up.
(Speculation is not the same as knowledge.)


## A note about the license

This is on a Creative Commons "CC0 1.0 Universal" license so you can copy, 
paste and modify any part of this code without attribution.  
That seems reasonable for sample code that
most would use in precisely that way.

However, taking a wholesale copy and representing it as your own work would be
reprehensible.  Few people pay respect to a person who has done such a thing.
In the words of one [very resilient duck](https://en.wikipedia.org/wiki/Daffy_Duck),
"desthpicable."

If you like, you can provide attribution with a reference to this project, e.g.
"Learned from telegraphy-interactive/paperclip-sample on GitHub,
https://github.com/telegraphy-interactive/paperclip-sample"
... or something to that effect.

