def rst_test(a):
    """This should be shown in rst formatting

    Args:
        a: The parameter

    Example:
        This is how you can use this function:

        .. code-block:: python

            result = test(3)
            print(result)
            nestedcss = "color: red"

        The injections are nested by nvim-treesitter
    """
    testcss = "background-color: pink"
    testhtml = "<p>very great html</p>"
    testHTML = "<p>very great html</p>"
    testjs = "const x=5"
    return [testcss, testhtml, testjs, testHTML]
