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
