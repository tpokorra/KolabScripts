Cypress.Commands.add('login_wap', (u, p) => {
	cy.visit("/kolab-webadmin")
	cy.get('#login_name').clear().type(u)
	cy.get('#login_pass').clear().type(p)
	cy.get('#login_submit').click()
})

Cypress.Commands.add('logout_wap', () => {
	cy.get('.logout').click()
})

Cypress.Commands.add('create_user', (
        { 
			prefix = "user",
			overall_quota = null,
			default_quota = null,
			max_accounts = null,
			default_quota_verify = null,
			default_role_verify = null,
			mail_quota = null,
			username = null,
			password = null,
			uid = null,
			alias = null,
			forward_to = null,
			expected_message_contains = null,
			role = null
	}) => {
		assert.isNotNull(username, "username must have a value")

		cy.get("#main .user").click()
		cy.wait(500)
		cy.get("#user-form .form [name=givenname]").clear().type(username)
		cy.get("#user-form .form [name=sn]").clear().type(username)
		if (prefix!="admin") {
			cy.get("#user-form .form [name=mail]").then((elem) => {
				let emailLogin = elem.val()
				//mylog(emailLogin)
			})
		} else {
			//elem = driver.find_element_by_link_text("System")
			//emailLogin = driver.find_element_by_name("uid").get_attribute('value')
		}
		
		cy.get("#user-form #tab2 a").click()
		cy.wait(500)
		cy.get("#user-form [name=userpassword]").clear().type(password)
		cy.get("#user-form [name=userpassword2]").clear().type(password)
		cy.get("#user-form input.submit").click()
})

