RSpec::describe Article do

  before :example do
    # most of these tests use JavaScript
    Capybara.current_driver = :webkit
  end
  after :example do
    Capybara.use_default_driver
  end

  it 'new article without picture shows no picture on view' do
    start_a_new_article
    click_button('Create Article')
    assert_no_selector('img')
  end

  it 'new article accepts an image attachment' do
    start_a_new_article
    add_image_to_article
    click_button('Create Article')
    image = find('img')
    expect(image[:src]).to have_content(valid_image_name)
  end

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

  context 'edit existing article' do
    before :example do
      start_a_new_article
      click_button('Create Article')
      visit articles_path
      find(:xpath, "//ul/li[position()=1]/a").click
      click_link 'Edit this'
      add_image_to_article
    end

    it 'can add and display an image' do
      click_button('Update Article')
      image = find('img')
      expect(image[:src]).to have_content(valid_image_name)
    end

    it 'can add multiple image attachments' do
      second_image_name = 'second_image.png'
      add_image_to_article(second_image_name)
      click_button('Update Article')
      assert_selector('img', count: 2)
      images = all('img')
      expect(images[0][:src]).to have_content(valid_image_name)
      expect(images[1][:src]).to have_content(second_image_name)
    end

    it 'can delete one of multiple image attachments' do
      second_image_name = 'second_image.png'
      add_image_to_article(second_image_name)
      click_button('Update Article')
      Rails.logger.info('about to edit')
      click_link('Edit this')
      within(:xpath, '//fieldset[position()=1]') do
        click_link('Delete image')
      end
      click_button('Update Article')
      assert_selector('img', count: 1)
      images = all('img')
      expect(images[0][:src]).to have_content(second_image_name)
    end

    it 'can delete the one and only image attachment' do
      click_button('Update Article')
      click_link('Edit this')
      click_link('Delete image')
      click_button('Update Article')
      expect { 
        find('img') 
      }.to raise_error(Capybara::ElementNotFound)
    end
  end

  #
  # Some helper methods
  #

  def valid_image_name
    'valid_image.jpg'
  end

  def add_image_to_article(name=valid_image_name)
    click_link('Add Image')
    image_file_name = File.join(File.absolute_path('..', File.dirname(__FILE__)), 'resources', name)
    within(:xpath, '//fieldset[position()=last()]') do
      attach_file 'Image', image_file_name
      fill_in 'Caption', with: Forgery(:lorem_ipsum).title
    end
  end

  def start_a_new_article
    visit new_article_path
    fill_in 'Title', with: Forgery(:lorem_ipsum).title
    fill_in 'Text', with: Forgery(:lorem_ipsum).sentences
  end

end
