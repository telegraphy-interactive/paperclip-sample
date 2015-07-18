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
