function login(u, p) {
	cy.visit("/kolab-webadmin")
	cy.get('#login_name').clear().type(u)
	cy.get('#login_pass').clear().type(p)
	cy.get('#login_submit').click()
}

describe('create testerino', function() {
	it('login and out', function() {
		login("cn=Directory Manager", "test")
		cy.get('#topmenu .logout').should("be.visible").click()
	})
	it('create user', function() {
		login("cn=Directory Manager", "test")
		cy.wait(500)
		cy.get("#main .user").click()
		cy.wait(500)
		cy.get("#user-form .form [name=givenname]").clear().type("Max")
		cy.get("#user-form .form [name=sn]").clear().type("Musterman")
		cy.get("#user-form .form [name=initials]").clear().type("MM")
		cy.get("#user-form .form [name=o]").clear().type("Max Musterman's Farb Tapeten Königreich")
		cy.get("#user-form .form [name=title]").clear().type("Tapetenmeister")
		
		cy.get("#user-form #tab2 a").click()
		cy.wait(500)
		cy.get("#user-form [name=userpassword]").clear().type("testtest")
		cy.get("#user-form [name=userpassword2]").clear().type("testtest")
		cy.get("#user-form input.submit").click()

	})
	it('login as user and change stuff', function() {
		login("musterman", "testtest")
		cy.wait(500)
		cy.get("#main .user").click()
	
		cy.get("#userlist .selectable").first().click()
		cy.wait(2500)
		cy.get("#user-form .form [name=initials]").clear().type("MMMMMMMM")
		cy.get("#user-form .form [name=o]").clear().type("MAXimal Ideenlose Org.")
		cy.get("#user-form .form [name=title]").clear().type("Nothing, just nothing")
		cy.get("#user-form input.submit").click()
	})
	it('login again and check infos', function() {
		login("musterman", "testtest")
		cy.wait(500)
		cy.get("#main .user").click()
		cy.get("#userlist .selectable").first().click()
		cy.wait(500)
		cy.get("#user-form .form [name=initials]").should('has.value', "MMMMMMMM")
		cy.get("#user-form .form [name=o]").should("has.value","MAXimal Ideenlose Org.")
		cy.get("#user-form .form [name=title]").should("has.value","Nothing, just nothing")
		cy.get('#topmenu .logout').should("be.visible").click()

	})
	it('change password', function() {
		login("musterman", "testtest")
		cy.wait(500)
		cy.get("#main .user").click()
		cy.get("#userlist .selectable").first().click()
		cy.wait(500)
		cy.get("#user-form #tab2 a").click()
		cy.wait(500)
		cy.get("#user-form [name=userpassword]").clear().type("testtesttest")
		cy.get("#user-form [name=userpassword2]").clear().type("testtesttest")
		cy.get("#user-form input.submit").click()
	})
	it('login with new password', function() {
		login("musterman", "testtesttest")
		cy.get('#topmenu .logout').should("be.visible").click()
	})
	it('delete test user', function() {
		login("cn=Directory Manager", "test")
		cy.wait(500)
		cy.get("#main .user").click()
		cy.get("#userlist .selectable").first().click()
		cy.wait(2500)
		cy.get("#user-form .formbuttons input[onclick*=delete]").click()
	})
})
