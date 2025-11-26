local unittest = require("tests.unittest")
local draw_data = require("ui.draw_queue.draw_data")

local T = {}

function T.tear_down()
    draw_data.clear()
end

function T.test_bake_translations()
    local ids = {}
    table.insert(ids, draw_data.make_point(9, 9))
    draw_data.make_push_translation(10, 10)
    table.insert(ids, draw_data.make_placement(1, 2, 3, 4))
    table.insert(ids, draw_data.make_point(4, 4))
    table.insert(ids, draw_data.make_point_cluster(1, 2, 3, 4, 5, 6, 7, 8))
    draw_data.make_push_translation(10, 10)
    table.insert(ids, draw_data.make_placement(1, 2, 3, 4))
    table.insert(ids, draw_data.make_point(4, 4))
    table.insert(ids, draw_data.make_point_cluster(1, 2, 3, 4, 5, 6, 7, 8))
    draw_data.make_pop_translation()
    draw_data.make_pop_translation()
    table.insert(ids, draw_data.make_point(9, 9))

    draw_data.bake_translations()

    unittest.assert_equal_lists({ draw_data.get_point(ids[1]) }, { 9, 9 })

    unittest.assert_equal_lists({ draw_data.get_placement(ids[2]) }, { 11, 12, 13, 14 })
    unittest.assert_equal_lists({ draw_data.get_point(ids[3]) }, { 14, 14 })
    unittest.assert_equal_lists({ draw_data.get_point_cluster(ids[4]) }, { 11, 12, 13, 14, 15, 16, 17, 18 })

    unittest.assert_equal_lists({ draw_data.get_placement(ids[5]) }, { 21, 22, 23, 24 })
    unittest.assert_equal_lists({ draw_data.get_point(ids[6]) }, { 24, 24 })
    unittest.assert_equal_lists({ draw_data.get_point_cluster(ids[7]) }, { 21, 22, 23, 24, 25, 26, 27, 28 })

    unittest.assert_equal_lists({ draw_data.get_point(ids[8]) }, { 9, 9 })
end

return T
