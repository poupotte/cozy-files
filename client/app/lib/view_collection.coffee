BaseView = require 'lib/base_view'

# View that display a collection of subitems
# used to DRY views
# Usage : new ViewCollection(collection:collection)
# Automatically populate itself by creating a itemView for each item
# in its collection

# can use a template that will be displayed alongside the itemViews

# itemView       : the Backbone.View to be used for items
# itemViewOptions : the options that will be passed to itemViews
# collectionEl : the DOM element's selector where the itemViews will
#                be displayed. Automatically falls back to el if null

module.exports = class ViewCollection extends BaseView

    collectionEl: null
    template: -> ''
    itemview: null
    views: {}
    itemViewOptions: ->

    # Gets the selector of the item views
    getItemViewSelector: ->
        classNames = @itemview::className.replace ' ', '.'
        return "#{@itemview::tagName}.#{classNames}"

    # add 'empty' class to view when there is no subview
    onChange: ->
        @$el.toggleClass 'empty', _.size(@views) is 0

    # we append the views at a specific index
    # based on their order in the collection
    appendView: (view) ->
        index = @collection.indexOf view.model
        if index is 0 # insert at the beginning
            @$collectionEl.prepend view.$el
        else
            selector = @getItemViewSelector()
            view.$el.insertAfter $(selector).eq(index - 1)

    # bind listeners to the collection
    initialize: ->
        super
        @views = {}
        @listenTo @collection, "reset",   @onReset
        @listenTo @collection, "add",     @addItem
        @listenTo @collection, "remove",  @removeItem
        @listenTo @collection, "sort",    @onSort

        @collectionEl = el if not @collectionEl?

    # if we have views before a render call, we detach them
    render: ->
        view.$el.detach() for id, view of @views
        super

    # after render, we reattach the views
    afterRender: ->
        @$collectionEl = $ @collectionEl
        @appendView view for id, view of @views
        @onReset @collection
        @onChange @views

    # destroy all sub views before remove
    remove: ->
        @onReset []
        super

    # event listener for reset
    onReset: (newcollection) ->
        view.remove() for id, view of @views
        newcollection.forEach @addItem

    # event listeners for add
    addItem: (model) =>
        options = _.extend {}, model: model, @itemViewOptions(model)
        view = new @itemview options
        @views[model.cid] = view.render()
        @appendView view
        @onChange @views

    # event listeners for remove
    removeItem: (model) =>
        @views[model.cid].remove()
        delete @views[model.cid]

        @onChange @views

    # We don't re-render the view if the order has not changed
    # Based on Marionette.ViewCollection
    onSort: ->
        selector = @getItemViewSelector()
        $itemViews = $ selector
        orderChanged = @collection.find (item, index) =>
            view = @views[item.cid]
            indexView = $itemViews.index view.$el
            return view and indexView isnt index

        @render() if orderChanged
