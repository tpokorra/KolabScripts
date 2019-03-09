import '../support/helpers.js'

function log(message) {
//      cy.writeFile('/tmp/debug.log', message, { flag: 'a+' })
        throw "log: " + message
}

function generateUserName({ prefix = "user"}) {
        let now = new Date();
        return prefix + now.getFullYear()+("0" + (now.getMonth() + 1)).slice(-2)+("0" + now.getDate()).slice(-2)+now.getHours()+now.getMinutes()+now.getSeconds()
}

function helper_user_edits_himself() {
	cy.get("div[class='settings']").click()
	cy.get("#user-form [name=initials]").clear().type("T")
	cy.get("#user-form input.submit").click()
	cy.get("#message").should('have.text', 'User updated successfully.')
}

let DirManPwd="test"
let UserPwd="Test1234!."

describe('test edit user himself', function() {
	it('test edit user himself', function() {
		cy.login_wap("cn=Directory Manager", DirManPwd)
		cy.wait(500)
		let emailLogin = generateUserName({prefix: "user"})

		cy.create_user({prefix: "user", username: emailLogin, password: UserPwd})
		cy.logout_wap()
		cy.login_wap(emailLogin, UserPwd)
		helper_user_edits_himself()
		cy.logout_wap()
	})
/*
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
*/
})
