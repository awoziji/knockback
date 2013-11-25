describe 'Knockback.js with Backbone Supermodel', ->

  # import Underscore (or Lo-Dash with precedence), Backbone, Knockout, and Knockback
  _ = window._ or require?('underscore')
  Backbone = window.Backbone or require?('backbone')
  Supermodel = window.Supermodel or require?('supermodel')
  ko = window.ko or require?('knockout')
  kb = window.kb or require?('knockback')

  it 'TEST DEPENDENCY MISSING', (done) ->
    assert.ok(!!ko, 'ko')
    assert.ok(!!_, '_')
    assert.ok(!!Backbone, 'Backbone')
    assert.ok(!!kb, 'kb')
    assert.ok(!!Supermodel, 'Supermodel')
    assert.ok(!!kb, 'kb')
    done()

  window.Person = Supermodel.Model.extend({})
  window.BestFriends = Supermodel.Model.extend({})
  window.Building = Supermodel.Model.extend({})

  Person.has()
    .many('friends', {model: Person, inverse: 'friends_with_me', collection: Backbone.Collection})
    .many('friends_with_me', {model: Person, inverse: 'friends', collection: Backbone.Collection})
    .one('occupies', {model: Building, inverse: 'occupants'})
    .one('best_friend', {model: Person, inverse: 'best_friends_with_me'})
    .many('best_friends_with_me', {model: Person, inverse: 'best_friend', collection: Backbone.Collection})

  Building.has()
    .many('occupants', {model: Person, inverse: 'occupies', collection: Backbone.Collection})

  it '1. Model with HasMany relations: A house with multiple people living in it', (done) ->
    kb.statistics = new kb.Statistics() # turn on stats

    john = Person.create({
      id: 'person-1-1'
      name: 'John'
    })

    paul = Person.create({
      id: 'person-1-2'
      name: 'Paul'
    })

    our_house = Building.create({
      id: 'house-1-1'
      location: 'in the middle of the street'
    })
    our_house.occupants().reset([john, paul])

    house_view_model = new kb.ViewModel(our_house)
    assert.equal(house_view_model.location(), 'in the middle of the street', 'In the right place')
    assert.equal(house_view_model.occupants().length, 2, 'Expected occupant count')
    for occupant_observable in house_view_model.occupants()
      assert.ok(_.contains(['John', 'Paul'], occupant_observable.name()), 'Expected name')
      assert.equal(occupant_observable.occupies().location(), 'in the middle of the street', 'Expected location')

      # nested check
      assert.equal(occupant_observable.occupies().occupants().length, 2, "Excepted occupant count")
      for occupant_observable2 in occupant_observable.occupies().occupants()
        assert.ok(_.contains(['John', 'Paul'], occupant_observable2.name()), 'Expected name')
        assert.equal(occupant_observable2.occupies().location(), 'in the middle of the street', 'Expected location')

    kb.release(house_view_model)

    assert.equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
    done()

  it '2. Collection with models with HasMany relations: Multiple houses with multiple people living in them', (done) ->
    kb.statistics = new kb.Statistics() # turn on stats

    john = Person.create({
      id: 'person-2-1'
      name: 'John'
    })
    paul = Person.create({
      id: 'person-2-2'
      name: 'Paul'
    })
    george = Person.create({
      id: 'person-2-3'
      name: 'George'
    })
    ringo = Person.create({
      id: 'person-2-4'
      name: 'Ringo'
    })

    abbey_flats = Building.create({
      id: 'house-2-1'
      location: 'one side of the street'
    })
    abbey_flats.occupants().reset([john, paul, george, ringo])
    abbey_studios = Building.create({
      id: 'studio-2-2'
      location: 'the other side of the street'
    })

    # check the set up state
    places = new kb.Collection([abbey_flats, abbey_studios])
    places_observable = kb.collectionObservable(places, {view_model: kb.ViewModel})
    for place_view_model in places_observable()
      if place_view_model.id() == 'house-2-1'
        assert.equal(place_view_model.location(), 'one side of the street', 'In the right place')
        assert.equal(place_view_model.occupants().length, 4, "Everyone is here")
        for occupant_observable in place_view_model.occupants()
          assert.ok(_.contains(['John', 'Paul', 'George', 'Ringo'], occupant_observable.name()), 'Expected name')
          assert.equal(occupant_observable.occupies().location(), 'one side of the street', 'Expected location')

          # nested check
          assert.equal(occupant_observable.occupies().occupants().length, 4, "Everyone is here")
          for occupant_observable2 in occupant_observable.occupies().occupants()
            assert.ok(_.contains(['John', 'Paul', 'George', 'Ringo'], occupant_observable2.name()), 'Expected name')
            assert.equal(occupant_observable2.occupies().location(), 'one side of the street', 'Expected location')
      else
        assert.equal(place_view_model.location(), 'the other side of the street', 'In the right place')
        assert.equal(place_view_model.occupants().length, 0, "No one is here")

    # a beattle crosses the road
    abbey_studios.occupants().add(john)

    for place_view_model in places_observable()
      if place_view_model.id() == 'house-2-1'
        assert.equal(place_view_model.location(), 'one side of the street', 'In the right place')
        assert.equal(place_view_model.occupants().length, 3, "Almost everyone is here")
        for occupant_observable in place_view_model.occupants()
          assert.ok(_.contains(['Paul', 'George', 'Ringo'], occupant_observable.name()), 'Expected name')
          assert.equal(occupant_observable.occupies().location(), 'one side of the street', 'Expected location')

          # nested check
          assert.equal(occupant_observable.occupies().occupants().length, 3, "Almost everyone is here")
          for occupant_observable2 in occupant_observable.occupies().occupants()
            assert.ok(_.contains(['Paul', 'George', 'Ringo'], occupant_observable2.name()), 'Expected name')
            assert.equal(occupant_observable2.occupies().location(), 'one side of the street', 'Expected location')
      else
        assert.equal(place_view_model.location(), 'the other side of the street', 'In the right place')
        assert.equal(place_view_model.occupants().length, 1, "In the studio")
        for occupant_observable in place_view_model.occupants()
          assert.equal(occupant_observable.name(), 'John', 'Expected name')
          assert.equal(occupant_observable.occupies().location(), 'the other side of the street', 'Expected location')

          # nested check
          assert.equal(occupant_observable.occupies().occupants().length, 1, "In the studio")
          for occupant_observable2 in occupant_observable.occupies().occupants()
            assert.equal(occupant_observable2.name(), 'John', 'Expected name')
            assert.equal(occupant_observable2.occupies().location(), 'the other side of the street', 'Expected location')

    kb.release(places_observable)

    assert.equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
    done()

  it '3. Model with recursive HasMany relations: Person with users who are people', (done) ->
    kb.statistics = new kb.Statistics() # turn on stats

    george = Person.create({
      id: 'person-3-3'
      name: 'George'
      # friends: ['person-3-1', 'person-3-2', 'person-3-4']
    })
    john = Person.create({
      id: 'person-3-1'
      name: 'John'
      # friends: ['person-3-2', 'person-3-3', 'person-3-4']
      # best_friend: george
    })
    george.best_friend(john)
    paul = Person.create({
      id: 'person-3-2'
      name: 'Paul'
      # friends: ['person-3-1', 'person-3-3', 'person-3-4']
      # best_friend: george
    })
    ringo = Person.create({
      id: 'person-3-4'
      name: 'Ringo'
      # friends: ['person-3-1', 'person-3-2', 'person-3-3']
    })
    george.friends().reset([john, paul, ringo])
    john.friends().reset([paul, george, ringo]); john.best_friend(george)
    paul.friends().reset([john, george, ringo]); paul.best_friend(george)
    ringo.friends().reset([john, paul, george])
    john_view_model = new kb.ViewModel(john)
    assert.equal(john_view_model.name(), 'John', "Name is correct")
    for friend in john_view_model.friends()
      assert.ok(_.contains(['Paul', 'George', 'Ringo'], friend.name()), 'Expected name')
    assert.equal(john_view_model.best_friend().name(), 'George', 'Expected name')
    # assert.equal(john_view_model.best_friends_with_me()[0].name(), 'George', 'Expected name')
    kb.release(john_view_model); john_view_model = null

    paul_view_model = new kb.ViewModel(paul)
    assert.equal(paul_view_model.name(), 'Paul', "Name is correct")
    for friend in paul_view_model.friends()
      assert.ok(_.contains(['John', 'George', 'Ringo'], friend.name()), 'Expected name')
    assert.equal(paul_view_model.best_friend().name(), 'George', 'Expected name')
    # assert.equal(paul_view_model.best_friends_with_me().length, 0, 'No best friends with me')
    kb.release(paul_view_model); paul_view_model = null

    george_view_model = new kb.ViewModel(george)
    assert.equal(george_view_model.name(), 'George', "Name is correct")
    for friend in george_view_model.friends()
      assert.ok(_.contains(['John', 'Paul', 'Ringo'], friend.name()), 'Expected name')
    assert.equal(george_view_model.best_friend().name(), 'John', 'Expected name')
    # assert.equal(george_view_model.best_friends_with_me()[0].name(), 'John', 'Expected name')
    # assert.equal(george_view_model.best_friends_with_me()[1].name(), 'Paul', 'Expected name')
    kb.release(george_view_model); george_view_model = null

    assert.equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
    done()

  it '4. After view model create, add models', (done) ->
    Occupant = Supermodel.Model.extend({})
    House = Supermodel.Model.extend({})
    House.has()
      .many('occupants', {model: Occupant, inverse: 'livesIn', collection: Backbone.Collection})
    Occupant.has()
      .one('livesIn', {model: House, inverse: 'occupants'})

    bob = Occupant.create({id: 'person-1', name: 'Bob'})
    fred = Occupant.create({id: 'person-2', name: 'Fred'})

    house = House.create({
      location: 'In the middle of our street'
    })

    # confirm no occupants
    view_model = kb.viewModel(house)
    assert.equal(view_model.occupants().length, 0, "no occupants")

    occupants_relationship = house.occupants()
    occupants_relationship.add(bob)
    occupants_relationship.add(fred)
    assert.equal(view_model.occupants().length, 2, 'two occupants')
    assert.equal(view_model.occupants()[0].name(), 'Bob', 'Bob is in the view model relationship')
    assert.equal(view_model.occupants()[1].name(), 'Fred', 'Fred is in the view model relationship')
    done()

  # it '5. bug fix for relational models https://github.com/kmalakoff/knockback/issues/34', (done) ->
  #   Book = Supermodel.Model.extend({
  #     defaults:
  #       name: 'untitled'
  #     idAttribute: '_id'
  #   })
  #   Author = Supermodel.Model.extend({
  #     defaults:
  #       name: 'untitled'
  #     idAttribute: '_id'
  #   })
  #   Author.has()
  #     .many('books', {model: Book, inverse: 'author', collection: Backbone.Collection})
  #   Book.has()
  #     .one('author', {model: Author, inverse: 'books'})

  #   BookStore = Supermodel.Model.extend({})
  #   BookStore.has()
  #     .many('books', {model: Book, inverse: 'bookstore', collection: Backbone.Collection})
  #     .many('authors', {model: Author, inverse: 'bookstore', collection: Backbone.Collection})

  #   bs = BookStore.create({
  #     books:[{_id:"b1", name: "Book One", author: "a1"}, {_id:"b2", name: "Book Two", author: "a1"}],
  #     authors:[{name: 'fred', _id: "a1"}, {name: 'ted', _id: "a2"}]
  #   })

  #   BookViewModel = kb.ViewModel.extend({
  #     constructor: (model) ->
  #       kb.ViewModel.prototype.constructor.apply(this, arguments)
  #       this.editMode = ko.observable()

  #       @edit = =>
  #         model._save = model.toJSON()
  #         @editMode(true)

  #       @confirm = =>
  #         model._save = null
  #         @editMode(false)

  #       @cancel = =>
  #         model.set(model._save)
  #         @editMode(false)
  #       @
  #   })

  #   view_model = {
  #     books: kb.collectionObservable(bs.books(), {
  #       factories:
  #         models: BookViewModel
  #         'models.author.books.models': BookViewModel
  #     })
  #   }

  #   for book in view_model.books()
  #     author = book.author()
  #     for authored_book in author.books()
  #       authored_book.editMode(true)
  #       assert.equal(authored_book.editMode(), true, 'edit mode set')
  #   done()

  it '6. Inferring observable types: from the start', (done) ->
    kb.statistics = new kb.Statistics() # turn on stats

    person1 = Person.create({id: 'person-6-1', name: 'Daddy'})
    person2 = Person.create({id: 'person-6-2', name: 'Mommy'})
    house = Building.create({id: 'house-6-1', name: 'Home Sweet Home'}); house.occupants().reset([person1, person2])
    person1.friends().add(person2); person2.best_friend(person1)

    view_model_person1 = kb.viewModel(person1)
    view_model_house1 = kb.viewModel(house)

    # check friends
    assert.equal(view_model_person1.friends().length, 1, 'person1 has one friend')
    assert.equal(view_model_person1.friends()[0].name(), 'Mommy', 'person1 is friends with Mommy')
    # assert.equal(view_model_person1.best_friends_with_me()[0].name(), 'Mommy', 'person1 is best friends with Mommy')

    # check occupants
    assert.equal(view_model_person1.occupies().name(), 'Home Sweet Home', 'person1 occupies home sweet home')
    assert.equal(view_model_house1.occupants().length, 2, 'house has two occupants')
    assert.equal(view_model_house1.occupants()[0].name(), 'Daddy', 'house has Daddy in it')

    # release
    kb.release(view_model_person1)
    kb.release(view_model_house1)

    assert.equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
    done()

  it '7a. Inferring observable types: late binding', (done) ->
    kb.statistics = new kb.Statistics() # turn on stats

    person1 = Person.create({id: 'person-7-1', name: 'Daddy'})
    person2 = Person.create({id: 'person-7-2', name: 'Mommy'})
    house = Building.create({id: 'house-7-1', name: 'Home Sweet Home'})

    view_model_person1 = kb.viewModel(person1)
    view_model_house1 = kb.viewModel(house)

    # inferred the relationship types
    assert.equal(view_model_person1.name(), 'Daddy', 'person1 name is Daddy')
    assert.equal(view_model_person1.friends().length, 0, 'person1 has no friends')
    # assert.equal(view_model_person1.best_friends_with_me().length, 0, 'person1 has not best_friends')
    assert.ok(view_model_person1.occupies() instanceof kb.ViewModel, 'person1 occupies is kb.ViewModel')
    assert.equal(view_model_house1.occupants().length, 0, 'house has no occupants')

    # add some friends
    person1.friends().add(person2); person2.best_friend(person1)
    assert.equal(view_model_person1.friends().length, 1, 'person1 has one friend')
    assert.equal(view_model_person1.friends()[0].name(), 'Mommy', 'person1 is friends with Mommy')
    # assert.equal(view_model_person1.best_friends_with_me()[0].name(), 'Mommy', 'person1 is best friends with Mommy')

    # add some occupants
    house.occupants().add(person1); house.occupants().add(person2)
    assert.equal(view_model_person1.occupies().name(), 'Home Sweet Home', 'person1 occupies home sweet home')
    assert.equal(view_model_house1.occupants().length, 2, 'house has two occupants')
    assert.equal(view_model_house1.occupants()[0].name(), 'Daddy', 'house has Daddy in it')

    # release
    kb.release(view_model_person1)
    kb.release(view_model_house1)

    assert.equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
    done()

  # it '7b. Inferring observable types: late binding (attribute setting)', (done) ->
  #   kb.statistics = new kb.Statistics() # turn on stats

  #   person1 = Person.create({id: 'person-7b-1', name: 'Daddy'})
  #   person2 = Person.create({id: 'person-7b-2', name: 'Mommy'})
  #   house = Building.create({id: 'house-7b-1', name: 'Home Sweet Home'})

  #   view_model_person1 = kb.viewModel(person1)
  #   view_model_house1 = kb.viewModel(house)

  #   # inferred the relationship types
  #   assert.equal(view_model_person1.name(), 'Daddy', 'person1 name is Daddy')
  #   assert.equal(view_model_person1.friends().length, 0, 'person1 has no friends')
  #   # assert.equal(view_model_person1.best_friends_with_me().length, 0, 'person1 has not best_friends')
  #   assert.ok(view_model_person1.occupies() instanceof kb.ViewModel, 'person1 occupies is kb.ViewModel')
  #   assert.equal(view_model_house1.occupants().length, 0, 'house has no occupants')

  #   # add some friends
  #   friends = _.clone(person1.friends().models); friends.push(person2); person1.friends().reset(friends)
  #   person2.best_friend(person1)
  #   assert.equal(view_model_person1.friends().length, 1, 'person1 has one friend')
  #   assert.equal(view_model_person1.friends()[0].name(), 'Mommy', 'person1 is friends with Mommy')
  #   # assert.equal(view_model_person1.best_friends_with_me()[0].name(), 'Mommy', 'person1 is best friends with Mommy')

  #   # add some occupants
  #   occupants = _.clone(house.occupants().models); occupants.push(person1); occupants.push(person2); house.occupants(occupants)
  #   assert.equal(view_model_person1.occupies().name(), 'Home Sweet Home', 'person1 occupies home sweet home')
  #   assert.equal(view_model_house1.occupants().length, 2, 'house has two occupants')
  #   assert.equal(view_model_house1.occupants()[0].name(), 'Daddy', 'house has Daddy in it')

  #   # release
  #   kb.release(view_model_person1)
  #   kb.release(view_model_house1)

  #   assert.equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
  #   done()

  it '8a. Customizing observable types: from the start', (done) ->
    kb.statistics = new kb.Statistics() # turn on stats

    class FriendViewModel extends kb.ViewModel
    class BestFriendViewModel extends kb.ViewModel
    class PersonViewModel extends kb.ViewModel
      constructor: (model, options) ->
        super(model, {factories: {
          'friends.models': FriendViewModel
          'best_friend': BestFriendViewModel
          'occupies': HouseViewModel
        }, options: options})
    class HouseViewModel extends kb.ViewModel
      constructor: (model, options) ->
        super(model, {factories: {
          'occupants.models': PersonViewModel
        }, options: options})

    person1 = Person.create({id: 'person-8-1', name: 'Daddy'})
    person2 = Person.create({id: 'person-8-2', name: 'Mommy'})
    family = new kb.Collection([person1, person2])
    house = Building.create({id: 'house-8-1', name: 'Home Sweet Home'}); house.occupants().reset([person1, person2])
    person1.friends().add(person2)
    person2.best_friend(person1)

    view_model_person1 = new PersonViewModel(person1)
    view_model_person2 = new PersonViewModel(person2)
    co_family = kb.collectionObservable(family, {view_model: PersonViewModel})
    view_model_house1 = new HouseViewModel(house)

    # check friends
    assert.equal(view_model_person1.friends().length, 1, 'person1 has one friend')
    assert.ok(view_model_person1.friends()[0] instanceof FriendViewModel, 'person1 is friends are FriendViewModel')
    assert.equal(view_model_person1.friends()[0].name(), 'Mommy', 'person1 is friends with Mommy')
    assert.equal(view_model_person1.best_friends_with_me().length, 1, 'person1 has one best friends')
    assert.equal(view_model_person1.best_friends_with_me()[0].name(), 'Mommy', 'person1 is best friends with Mommy')
    assert.ok(view_model_person2.best_friend() instanceof BestFriendViewModel, 'person2 is best friends are BestFriendViewModel')
    assert.equal(view_model_person2.best_friend().name(), 'Daddy', 'person2 is best friends with Daddy')
    assert.ok(view_model_person2.occupies() instanceof HouseViewModel, 'person2 is occupies HouseViewModel')

    # check occupants
    assert.equal(view_model_person1.occupies().name(), 'Home Sweet Home', 'person1 occupies home sweet home')
    assert.equal(view_model_house1.occupants().length, 2, 'house has two occupants')
    assert.ok(view_model_house1.occupants()[0] instanceof PersonViewModel, 'house has PersonViewModel in it')
    assert.equal(view_model_house1.occupants()[0].name(), 'Daddy', 'house has Daddy in it')
    assert.ok(view_model_house1.occupants()[0].occupies() instanceof HouseViewModel, 'person1 occupies has HouseViewModel')
    assert.equal(view_model_house1.occupants()[0].occupies().name(), 'Home Sweet Home', 'person1 occupies home sweet home')

    # release
    kb.release(view_model_person1)
    kb.release(view_model_person2)
    kb.release(co_family)
    kb.release(view_model_house1)

    assert.equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
    done()

  # it '8b. Customizing observable types: from the start (attribute setting)', (done) ->
  #   kb.statistics = new kb.Statistics() # turn on stats

  #   class FriendViewModel extends kb.ViewModel
  #   class BestFriendViewModel extends kb.ViewModel
  #   class PersonViewModel extends kb.ViewModel
  #     constructor: (model, options) ->
  #       super(model, {factories: {
  #         'friends.models': FriendViewModel
  #         'best_friend': BestFriendViewModel
  #         'occupies': HouseViewModel
  #       }, options: options})
  #   class HouseViewModel extends kb.ViewModel
  #     constructor: (model, options) ->
  #       super(model, {factories: {
  #         'occupants.models': PersonViewModel
  #       }, options: options})

  #   person1 = Person.create({id: 'person-8b-1', name: 'Daddy'})
  #   person2 = Person.create({id: 'person-8b-2', name: 'Mommy'})
  #   family = new kb.Collection([person1, person2])
  #   house = Building.create({id: 'house-8b-1', name: 'Home Sweet Home', occupants: [person1.toJSON()]})
  #   house.set({occupants: [person1.toJSON(), person2.toJSON()]})
  #   friends = _.clone(person1.friends().models); friends.push(person2); person1.friends().reset(friends)
  #   person2.best_friend(person1)

  #   view_model_person1 = new PersonViewModel(person1)
  #   view_model_person2 = new PersonViewModel(person2)
  #   co_family = kb.collectionObservable(family, {view_model: PersonViewModel})
  #   view_model_house1 = new HouseViewModel(house)

  #   # check friends
  #   assert.equal(view_model_person1.friends().length, 1, 'person1 has one friend')
  #   assert.ok(view_model_person1.friends()[0] instanceof FriendViewModel, 'person1 is friends are FriendViewModel')
  #   assert.equal(view_model_person1.friends()[0].name(), 'Mommy', 'person1 is friends with Mommy')
  #   assert.equal(view_model_person1.best_friends_with_me().length, 1, 'person1 has one best friends')
  #   assert.equal(view_model_person1.best_friends_with_me()[0].name(), 'Mommy', 'person1 is best friends with Mommy')
  #   assert.ok(view_model_person2.best_friend() instanceof BestFriendViewModel, 'person2 is best friends are BestFriendViewModel')
  #   assert.equal(view_model_person2.best_friend().name(), 'Daddy', 'person2 is best friends with Daddy')
  #   assert.ok(view_model_person2.occupies() instanceof HouseViewModel, 'person2 is occupies HouseViewModel')

  #   # check occupants
  #   assert.equal(view_model_person1.occupies().name(), 'Home Sweet Home', 'person1 occupies home sweet home')
  #   assert.equal(view_model_house1.occupants().length, 2, 'house has two occupants')
  #   assert.ok(view_model_house1.occupants()[0] instanceof PersonViewModel, 'house has PersonViewModel in it')
  #   assert.equal(view_model_house1.occupants()[0].name(), 'Daddy', 'house has Daddy in it')
  #   assert.ok(view_model_house1.occupants()[0].occupies() instanceof HouseViewModel, 'person1 occupies has HouseViewModel')
  #   assert.equal(view_model_house1.occupants()[0].occupies().name(), 'Home Sweet Home', 'person1 occupies home sweet home')

  #   # release
  #   kb.release(view_model_person1)
  #   kb.release(view_model_person2)
  #   kb.release(co_family)
  #   kb.release(view_model_house1)

  #   assert.equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
  #   done()

  it '9a. Customizing observable types: late binding', (done) ->
    kb.statistics = new kb.Statistics() # turn on stats

    class FriendViewModel extends kb.ViewModel
    class BestFriendViewModel extends kb.ViewModel
    class PersonViewModel extends kb.ViewModel
      constructor: (model, options) ->
        super(model, {factories: {
          'friends.models': FriendViewModel
          'best_friend': BestFriendViewModel
          'occupies': HouseViewModel
        }, options: options})
    class HouseViewModel extends kb.ViewModel
      constructor: (model, options) ->
        super(model, {factories: {
          'occupants.models': PersonViewModel
        }, options: options})

    person1 = Person.create({id: 'person-9-1', name: 'Daddy'})
    person2 = Person.create({id: 'person-9-2', name: 'Mommy'})
    family = new kb.Collection([person1, person2])
    house = Building.create({id: 'house-9-1', name: 'Home Sweet Home'})

    view_model_person1 = new PersonViewModel(person1)
    view_model_person2 = new PersonViewModel(person2)
    co_family = kb.collectionObservable(family, {view_model: PersonViewModel})
    view_model_house1 = new HouseViewModel(house)

    # check initial state
    assert.equal(view_model_person1.friends().length, 0, 'person1 has no friends')
    assert.equal(view_model_person1.best_friends_with_me().length, 0, 'person1 has no best friends')
    assert.ok(view_model_person2.best_friend() instanceof BestFriendViewModel, 'person2 is best friends are BestFriendViewModel')
    assert.ok(view_model_person2.occupies() instanceof HouseViewModel, 'person2 is occupies HouseViewModel')
    assert.equal(view_model_house1.occupants().length, 0, 'house has no occupants')

    # check friends
    person1.friends().add(person2); person2.best_friend(person1)
    assert.equal(view_model_person1.friends().length, 1, 'person1 has one friend')
    assert.ok(view_model_person1.friends()[0] instanceof FriendViewModel, 'person1 is friends are FriendViewModel')
    assert.equal(view_model_person1.friends()[0].name(), 'Mommy', 'person1 is friends with Mommy')
    assert.equal(view_model_person1.best_friends_with_me().length, 1, 'person1 has one best friends')
    assert.equal(view_model_person1.best_friends_with_me()[0].name(), 'Mommy', 'person1 is best friends with Mommy')
    assert.ok(view_model_person2.best_friend() instanceof BestFriendViewModel, 'person2 is best friends are BestFriendViewModel')
    assert.equal(view_model_person2.best_friend().name(), 'Daddy', 'person2 is best friends with Daddy')
    assert.ok(view_model_person2.occupies() instanceof HouseViewModel, 'person2 is occupies HouseViewModel')

    # check occupants
    house.occupants().add(person1); house.occupants().add(person2)
    assert.equal(view_model_person1.occupies().name(), 'Home Sweet Home', 'person1 occupies home sweet home')
    assert.equal(view_model_house1.occupants().length, 2, 'house has two occupants')
    assert.ok(view_model_house1.occupants()[0] instanceof PersonViewModel, 'house has PersonViewModel in it')
    assert.equal(view_model_house1.occupants()[0].name(), 'Daddy', 'house has Daddy in it')
    assert.ok(view_model_house1.occupants()[0].occupies() instanceof HouseViewModel, 'person1 occupies has HouseViewModel')
    assert.equal(view_model_house1.occupants()[0].occupies().name(), 'Home Sweet Home', 'person1 occupies home sweet home')

    # release
    kb.release(view_model_person1)
    kb.release(view_model_person2)
    kb.release(co_family)
    kb.release(view_model_house1)

    assert.equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
    done()

  # it '9b. Customizing observable types: late binding (atrributes setting)', (done) ->
  #   kb.statistics = new kb.Statistics() # turn on stats

  #   class FriendViewModel extends kb.ViewModel
  #   class BestFriendViewModel extends kb.ViewModel
  #   class PersonViewModel extends kb.ViewModel
  #     constructor: (model, options) ->
  #       super(model, {factories: {
  #         'friends.models': FriendViewModel
  #         'best_friend': BestFriendViewModel
  #         'occupies': HouseViewModel
  #       }, options: options})
  #   class HouseViewModel extends kb.ViewModel
  #     constructor: (model, options) ->
  #       super(model, {factories: {
  #         'occupants.models': PersonViewModel
  #       }, options: options})

  #   person1 = Person.create({id: 'person-9b-1', name: 'Daddy'})
  #   person2 = Person.create({id: 'person-9b-2', name: 'Mommy'})
  #   family = new kb.Collection([person1, person2])
  #   house = Building.create({id: 'house-9b-1', name: 'Home Sweet Home'})

  #   view_model_person1 = new PersonViewModel(person1)
  #   view_model_person2 = new PersonViewModel(person2)
  #   co_family = kb.collectionObservable(family, {view_model: PersonViewModel})
  #   view_model_house1 = new HouseViewModel(house)

  #   # check initial state
  #   assert.equal(view_model_person1.friends().length, 0, 'person1 has no friends')
  #   assert.equal(view_model_person1.best_friends_with_me().length, 0, 'person1 has no best friends')
  #   assert.ok(view_model_person2.best_friend() instanceof BestFriendViewModel, 'person2 is best friends are BestFriendViewModel')
  #   assert.ok(view_model_person2.occupies() instanceof HouseViewModel, 'person2 is occupies HouseViewModel')
  #   assert.equal(view_model_house1.occupants().length, 0, 'house has no occupants')

  #   # check friends
  #   friends = _.clone(person1.friends().models); friends.push(person2); person1.friends().reset(friends)
  #   person2.best_friend(person1)
  #   assert.equal(view_model_person1.friends().length, 1, 'person1 has one friend')
  #   assert.ok(view_model_person1.friends()[0] instanceof FriendViewModel, 'person1 is friends are FriendViewModel')
  #   assert.equal(view_model_person1.friends()[0].name(), 'Mommy', 'person1 is friends with Mommy')
  #   assert.equal(view_model_person1.best_friends_with_me().length, 1, 'person1 has one best friends')
  #   assert.equal(view_model_person1.best_friends_with_me()[0].name(), 'Mommy', 'person1 is best friends with Mommy')
  #   assert.ok(view_model_person2.best_friend() instanceof BestFriendViewModel, 'person2 is best friends are BestFriendViewModel')
  #   assert.equal(view_model_person2.best_friend().name(), 'Daddy', 'person2 is best friends with Daddy')
  #   assert.ok(view_model_person2.occupies() instanceof HouseViewModel, 'person2 is occupies HouseViewModel')

  #   # check occupants
  #   occupants = _.clone(house.occupants().models); occupants.push(person1); occupants.push(person2); house.set({occupants: occupants})
  #   assert.equal(view_model_person1.occupies().name(), 'Home Sweet Home', 'person1 occupies home sweet home')
  #   assert.equal(view_model_house1.occupants().length, 2, 'house has two occupants')
  #   assert.ok(view_model_house1.occupants()[0] instanceof PersonViewModel, 'house has PersonViewModel in it')
  #   assert.equal(view_model_house1.occupants()[0].name(), 'Daddy', 'house has Daddy in it')
  #   assert.ok(view_model_house1.occupants()[0].occupies() instanceof HouseViewModel, 'person1 occupies has HouseViewModel')
  #   assert.equal(view_model_house1.occupants()[0].occupies().name(), 'Home Sweet Home', 'person1 occupies home sweet home')

  #   # release
  #   kb.release(view_model_person1)
  #   kb.release(view_model_person2)
  #   kb.release(co_family)
  #   kb.release(view_model_house1)

  #   assert.equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
  #   done()

  it '10. Nested custom view models', (done) ->
    kb.statistics = new kb.Statistics() # turn on stats

    george = Person.create({
      id: 'person-10-3'
      name: 'George'
      # friends: ['person-10-1', 'person-10-2', 'person-10-4']
    })
    john = Person.create({
      id: 'person-10-1'
      name: 'John'
      # friends: ['person-10-2', 'person-10-3', 'person-10-4']
      # best_friend: george
    })
    george.best_friend(john)
    paul = Person.create({
      id: 'person-10-2'
      name: 'Paul'
      # friends: ['person-10-1', 'person-10-3', 'person-10-4']
      # best_friend: george
    })
    ringo = Person.create({
      id: 'person-10-4'
      name: 'Ringo'
      # friends: ['person-10-1', 'person-10-2', 'person-10-3']
    })
    george.friends().reset([john, paul, ringo])
    john.friends().reset([paul, george, ringo]); john.best_friend(george)
    paul.friends().reset([john, george, ringo]); paul.best_friend(george)
    ringo.friends().reset([john, paul, george])

    FriendViewModel = (model) ->
      @name = kb.observable(model, 'name')
      @type = ko.observable('friend')
      @
    BestFriendViewModel = (model) ->
      @name = kb.observable(model, 'name')
      @type = ko.observable('best_friend')
      @
    class BandMemberViewModel extends kb.ViewModel
      constructor: (model, options) ->
        super
        @type = ko.observable('band_member')

    collection_observable = kb.collectionObservable(new kb.Collection([john, paul, george, ringo]), {
      factories:
        models: BandMemberViewModel
        'models.best_friend': {create: (model, options) -> return if model then new BestFriendViewModel(model) else null}
        'models.friends.models': FriendViewModel
    })

    validateFriends = (co, names) ->
      for name in names
        found = false
        for vm in co()
          if vm.name and vm.name() == name
            found = true
            validateFriend(vm, name)
        assert.ok(found, "#{name} was found")
      return
    validateFriend = (vm, name) ->
      assert.equal(vm.type(), 'friend', "friend type matches for #{name}")
      assert.equal(vm.name(), name, "friend name matches for #{name}")
    validateBestFriend = (vm, name) ->
      assert.equal(vm.type(), 'best_friend', "best friend type matches for #{name}")
      assert.equal(vm.name(), name, "best friend name matches for #{name}")
    validateBandMember = (vm, name) ->
      assert.equal(vm.type(), 'band_member', "band member type matches for #{name}")
      assert.ok(vm instanceof BandMemberViewModel, "band member type matches for #{name}")
      assert.equal(vm.name(), name, "band member name matches for #{name}")

    validateBandMember(collection_observable()[0], 'John')
    validateBestFriend(collection_observable()[0].best_friend(), 'George')
    validateFriends(collection_observable()[0].friends, ['Paul', 'George', 'Ringo'])
    validateBandMember(collection_observable()[1], 'Paul')
    validateBestFriend(collection_observable()[1].best_friend(), 'George')
    validateFriends(collection_observable()[1].friends, ['John', 'George', 'Ringo'])
    validateBandMember(collection_observable()[2], 'George')
    validateBestFriend(collection_observable()[2].best_friend(), 'John')
    validateFriends(collection_observable()[2].friends, ['John', 'Paul', 'Ringo'])
    validateBandMember(collection_observable()[3], 'Ringo')
    assert.equal(collection_observable()[3].best_friend(), null, 'No best friend')
    validateFriends(collection_observable()[3].friends, ['John', 'Paul', 'George'])

    # and cleanup after yourself when you are done.
    kb.release(collection_observable)

    assert.equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
    done()

  it '11. Minimum factory tree for shared dependent models', (done) ->
    kb.statistics = new kb.Statistics() # turn on stats

    george = Person.create({
      id: 'person-11-3'
      name: 'George'
      # friends: ['person-11-1', 'person-11-2', 'person-11-4']
    })
    john = Person.create({
      id: 'person-11-1'
      name: 'John'
      # friends: ['person-11-2', 'person-11-3', 'person-11-4']
      # best_friend: george
    })
    george.best_friend(john)
    paul = Person.create({
      id: 'person-11-2'
      name: 'Paul'
      # friends: ['person-11-1', 'person-11-3', 'person-11-4']
      # best_friend: george
    })
    ringo = Person.create({
      id: 'person-11-4'
      name: 'Ringo'
      # friends: ['person-11-1', 'person-11-2', 'person-11-3']
    })
    george.friends().reset([john, paul, ringo])
    john.friends().reset([paul, george, ringo]); john.best_friend(george)
    paul.friends().reset([john, george, ringo]); paul.best_friend(george)
    ringo.friends().reset([john, paul, george])

    class window.PersonViewModel extends kb.ViewModel
      constructor: (model, options) ->
        super(model, {
          factories:
            'friends': PersonCollection
            'best_friend': PersonViewModel
            'best_friends_with_me': PersonViewModel
          options: options
        })

    class window.PersonCollection extends kb.CollectionObservable
      constructor: (collection, options) ->
        return super(collection, {
          factories:
            'models': PersonViewModel
          options: options
        })

    collection_observable1 = new PersonCollection(new kb.Collection([george, john, paul, ringo]))
    collection_observable2 = new PersonCollection(new kb.Collection([george, john, paul, ringo]), collection_observable1.shareOptions())

    assert.equal(collection_observable1.__kb.factory, collection_observable2.__kb.factory, "the factory should be shared")

    kb.release([collection_observable1, collection_observable2])

    view_model_george = new PersonViewModel(george)
    view_model_john = new PersonViewModel(john, view_model_george.shareOptions())
    view_model_paul = new PersonViewModel(john, view_model_john.shareOptions())
    view_model_ringo = new PersonViewModel(ringo, view_model_paul.shareOptions())

    view_model_george_john = view_model_george.friends()[0]
    assert.equal(view_model_george.__kb.factory, view_model_george_john.__kb.factory.parent_factory.parent_factory, "the factory should be shared: george")
    assert.equal(view_model_george.__kb.factory, view_model_john.__kb.factory, "the factory should be shared: john")
    assert.equal(view_model_george.__kb.factory, view_model_paul.__kb.factory, "the factory should be shared: paul")
    assert.equal(view_model_george.__kb.factory, view_model_ringo.__kb.factory, "the factory should be shared: ringo")

    kb.release([view_model_george, view_model_john, view_model_paul, view_model_ringo])

    assert.equal(kb.statistics.registeredStatsString('all released'), 'all released', "Cleanup: stats"); kb.statistics = null
    done()