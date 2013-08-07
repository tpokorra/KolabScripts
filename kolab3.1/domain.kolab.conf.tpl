[{$hosted_domain}]
base_dn = {$hosted_domain_root_dn}
primary_mail = %(givenname)s.%(surname)s@%(domain)s
autocreate_folders = {
        'Archive': {
        'quota': 0
        },
        'Calendar': {
        'annotations': {
        '/private/vendor/kolab/folder-type': "event.default",
        '/shared/vendor/kolab/folder-type': "event",
        },
        },
        'Configuration': {
        'annotations': {
        '/private/vendor/kolab/folder-type': "configuration.default",
        '/shared/vendor/kolab/folder-type': "configuration.default",
        },
        },
        'Drafts': {
        'annotations': {
        '/private/vendor/kolab/folder-type': "mail.drafts",
        },
        },
        'Contacts': {
        'annotations': {
        '/private/vendor/kolab/folder-type': "contact.default",
        '/shared/vendor/kolab/folder-type': "contact",
        },
        },
        'Journal': {
        'annotations': {
        '/private/vendor/kolab/folder-type': "journal.default",
        '/shared/vendor/kolab/folder-type': "journal",
        },
        },
        'Notes': {
        'annotations': {
        '/private/vendor/kolab/folder-type': 'note.default',
        '/shared/vendor/kolab/folder-type': 'note',
        },
        },
        'Sent': {
        'annotations': {
        '/private/vendor/kolab/folder-type': "mail.sentitems",
        },
        },
        'Spam': {
        'annotations': {
        '/private/vendor/kolab/folder-type': "mail.junkemail",
        },
        },
        'Tasks': {
        'annotations': {
        '/private/vendor/kolab/folder-type': "task.default",
        '/shared/vendor/kolab/folder-type': "task",
        },
        },
        'Trash': {
        'annotations': {
        '/private/vendor/kolab/folder-type': "mail.wastebasket",
        },
        },
        }
