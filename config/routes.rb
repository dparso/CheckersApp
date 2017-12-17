Rails.application.routes.draw do
	root "checkers_app#index"
	get "/" => "checkers_app#index"
	post "/" => "checkers_app#select"
	get "/hello" => "checkers_app#hello"

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
