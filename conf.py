extensions = [
    "myst_nb",
    "sphinx_thebe",
]

thebe_config = {
    "repository_url": "https://github.com/<ton-utilisateur>/sphinx-thebe-demo",
    "repository_branch": "main",
}

html_theme = "sphinx_book_theme"

html_theme_options = {
    "launch_buttons": {
        "thebe": True,
    },
    "use_repository_button": True,
}

source_suffix = {
    '.rst': 'restructuredtext',
    '.md': 'markdown',
}
