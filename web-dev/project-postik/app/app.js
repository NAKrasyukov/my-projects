
const express = require('express');
const app = express();
const expressWs = require('express-ws');
expressWs(app);
const mongoose = require('mongoose');
console.log("Mongoose version: " + require('mongoose').version);
const passport = require('passport');
const session = require('express-session');
const bcrypt = require('bcrypt');
const LocalStrategy = require('passport-local').Strategy;
const ejs = require('ejs');
const multer = require('multer');
const path = require('path');

const bodyParser = require('body-parser');
const {response} = require("express");

const stile = ``;
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.set('view engine', 'ejs');
app.use('/assets', express.static(__dirname + '/assets'));

// Подключаемся к базе данных MongoDB
mongoose.connect('mongodb://127.0.0.1:27017/mydatabase', { useNewUrlParser: true, useUnifiedTopology: true })
    .then(() => console.log('MongoDB connected...'))
    .catch(err => console.log(err));

// Создаем модель пользователя
const User = mongoose.model('users', {
  username: String,
  password: String,
  role: {
    type: String,
    enum: ['User', 'SuperUser', 'Moderator', 'Admin'],
    default: 'User'
  }
});

// Настраиваем аутентификацию с помощью Passport.js
passport.use(new LocalStrategy((username, password, done) => {
  User.findOne({ username: username }, (err, user) => {
    if (err) return done(err);
    if (!user) return done(null, false, { message: 'Incorrect username.' });
    bcrypt.compare(password, user.password, (err, res) => {
      if (err) return done(err);
      if (res === false) return done(null, false, { message: 'Incorrect password.' });
      return done(null, user);
    });
  });
}));

passport.serializeUser((user, done) => {
  done(null, user.id);
});

passport.deserializeUser((id, done) => {
  User.findById(id, (err, user) => {
    done(err, user);
  });
});

// Настраиваем сессии
app.use(session({
  secret: 'mysecret',
  resave: false,
  saveUninitialized: false
}));

// Используем Passport для аутентификации
app.use(passport.initialize());
app.use(passport.session());

// Настраиваем маршруты
app.get('/', (req, res) => {
  if (!req.user) {
    return res.sendFile(__dirname + '/index.html');
  }

  const username = req.user.username;
  const role = req.user.role;

  User.find({}, (err, users) => {
    if (err) {
      return res.status(500).send('Internal Server Error');
    }
    if(role === 'Moderator' || role === 'Admin'){
      return res.render('template', {
        title: 'Moderator Page',
        stile: stile,
        username: username,
        role: role,
        users: users
      });
    } else{
      return res.render('template', {
        title: 'Moderator Page',
        stile: stile,
        username: username,
        role: role,
      });
    }
  });
});
app.get('/register', (req, res) => {
    return res.sendFile(__dirname + '/register.html');

});

app.post('/login', passport.authenticate('local', {
  successRedirect: '/posts',
  failureRedirect: '/',
}));

app.post('/logout', function(req, res, next){
  req.logout(function(err) {
    if (err) { return next(err); }
    res.redirect('/');
  });
});

app.post('/register', async (req, res) => {
  const { email, birthdate, username, password } = req.body;
  const createdAt = new Date();
  const hashedPassword = await bcrypt.hash(password, 10);
  const user = new User({
    username: username,
    password: hashedPassword,
    role: 'User',
    email: email,
    birthdate: birthdate,
    createdAt: createdAt,
  });
  await user.save();
  res.redirect('/');
});


// Определяем схему поста
const postSchema = new mongoose.Schema({
  authorName: String,
  authorAvatar: String,
  createdAt: Date,
  text: String,
  attachments: [String]
});

// Создаем модель поста
const Post = mongoose.model('Post', postSchema);

// Определяем схему коммента
const commentSchema = new mongoose.Schema({
  comPostId:String,
  authorName: String,
  authorAvatar: String,
  createdAt: Date,
  text: String
});

// Создаем модель коммента
const Comment = mongoose.model('comments', commentSchema);

const profileSchema = new mongoose.Schema({
    profileUserId: String,
    userAvatar: String,
    userProfileBackground: String
});

const Profile = mongoose.model('profiles', profileSchema);

const chatSchema = new mongoose.Schema({
    user1Id: String,
    user2Id: String
});

const Chat = mongoose.model('chats', chatSchema);

const messagesSchema = new mongoose.Schema({
    chatId: String,
    senderId: String,
    text: String
});

const Message = mongoose.model('chatmessages', messagesSchema);


// Маршрут для отображения всех постов
app.get('/posts', async (req, res) => {

  const posts = await Post.find().exec();
  const comments = await Comment.find().exec();
  const Users = await User.find({},'_id username').exec();
  const chats = await Chat.find().exec();
  const messages = await Message.find().exec();
  try {
    if (!req.user) {
      return res.render('posts', {
        title: 'Moderator Page',
        stile: stile,
        logined: false,
        posts,
        comments
      });
    } else {
      const username = req.user.username;
      const role = req.user.role;
      const userid = req.user.id;

      if (role === 'Moderator' || role === 'Admin') {
        return res.render('posts', {
          title: 'Moderator Page',
          stile: stile,
          username: username,
          role: role,
          userid: userid,
          logined: true,
          posts,
          Users,
          chats,
          messages,
          comments
        });
      } else {
        return res.render('posts', {
          title: 'Moderator Page',
          stile: stile,
          username: username,
          role: role,
          userid: userid,
          logined: true,
          posts,
          Users,
          chats,
          messages,
          comments
        });
      }
    }
  } catch (err) {
    console.error(err);
    res.sendStatus(500);
  }
});

app.get('/posts/profile/:id', async (req, res) => {

    const posts = await Post.find().exec();
    const comments = await Comment.find().exec();
    const Users = await User.find({},'_id username').exec();
    const ProfilesUserId = req.params.id
    const ProfileUser = await User.findById(ProfilesUserId, '_id username').exec();
    const messages = await Message.find().exec();

    try {
        if (!req.user) {
            return res.sendFile(__dirname + '/index.html');
        } else {
            const username = req.user.username;
            const role = req.user.role;
            const userid = req.user.id;

            if (role === 'Moderator' || role === 'Admin') {
                return res.render('profile', {
                    title: 'Profile',
                    stile: stile,
                    username: username,
                    role: role,
                    userid: userid,
                    logined: true,
                    ProfilesUserId: ProfilesUserId,
                    ProfileUser: ProfileUser.toObject(),
                    posts,
                    comments,
                    messages,
                    Users
                });
            } else {
                return res.render('profile', {
                    title: 'Profile',
                    stile: stile,
                    username: username,
                    role: role,
                    userid: userid,
                    logined: true,
                    ProfilesUserId: ProfilesUserId,
                    ProfileUser: ProfileUser.toObject(),
                    posts,
                    comments,
                    messages,
                    Users
                });
            }
        }
    } catch (err) {
        console.error(err);
        res.sendStatus(500);
    }
});

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'assets/');
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, uniqueSuffix + extension);
  }
});

const upload = multer({ storage: storage });

app.post('/posts/profile/:id', upload.single('userAvatar'), upload.single('userProfileBackground'), async (req, res) => {
    try {
        const ProfilesUserId = req.params.id
        const { profileUserId } = req.body;
        let attachmentName = '';
        if (req.file) {
            attachmentName = req.file.filename;
            alert(attachmentName)
        }
        const profile = new Profile({
            profileUserId,
            userAvatar: userAvatar,
            userProfileBackground:userProfileBackground
        });
        //await profile.save();
        res.redirect(`/posts/profile/${ProfilesUserId}`);
    } catch (err) {
        console.error(err);
        res.sendStatus(500);
    }
});

app.post('/posts', upload.single('attachments'), async (req, res) => {
  try {
    const { authorName, authorAvatar, text } = req.body;
    const createdAt = new Date();
    let attachmentName = '';
    if (req.file) {
      attachmentName = req.file.filename;
    }
    const post = new Post({
      authorName,
      authorAvatar,
      createdAt,
      text,
      attachments: [attachmentName]
    });
    await post.save();
    res.redirect('/posts');
  } catch (err) {
    console.error(err);
    res.sendStatus(500);
  }
});

app.delete('/posts/:id', async (req, res) => {
  const postId = req.params.id

  try {
    // Удаляем пост из коллекции 'posts'
    await Post.findByIdAndDelete(postId)

    res.sendStatus(204) // Отправляем код 204 No Content, если удаление прошло успешно
  } catch (error) {
    console.error(error)
    res.sendStatus(500) // Отправляем код 500 Internal Server Error в случае ошибки
  }
});

app.post('/comments', async (req, res) => {
  try {
    //const { comPostId, authorName, text } = req.body;
    const createdAt = new Date();
    const comment = new Comment({
      comPostId: req.body.comPostId,
      authorName:req.body.authorName2,
      createdAt,
      text: req.body.text2
    });
    await comment.save();
    res.redirect('/posts');
  } catch (err) {
    console.error(err);
    res.sendStatus(500);
  }
});

app.post('/chat', async (req, res) => {
    try {
        const {user1Id, user2Id} = req.body;
        const chat = new Chat({
            user1Id: user1Id,
            user2Id: user2Id
        });
        await chat.save();
        //res.redirect('/posts');
    } catch (err) {
        console.error(err);
        res.sendStatus(500);
    }
});
app.post('/message', async (req, res) => {
    try {
        const {chatId, senderId, text} = req.body;
        const message = new Message({
            chatId: chatId,
            senderId: senderId,
            text: text
        });
        await message.save();
        //res.redirect('/posts');
    } catch (err) {
        console.error(err);
        res.sendStatus(500);
    }
});

app.post('/users', async (req, res) => {
    try {
        const {_id, username, password, role} = req.body;
        const hashedPassword = await bcrypt.hash(password, 10);
        if(await User.findById(_id).exec()){
            const user = await User.findById(_id).exec();

            if (user.password === password){
                await User.findByIdAndUpdate(_id, {
                    username: username,
                    role: role,
                });
                res.redirect('/');
            }else {
                await User.findByIdAndUpdate(_id, {
                    username: username,
                    password: hashedPassword,
                    role: role,
                });
                res.redirect('/');
            }

        }else{
            const user = new User({
                username: username,
                password: hashedPassword,
                role: role,
            });

            await user.save();
            res.redirect('/');
        }
    } catch (err) {
        console.error(err);
        res.sendStatus(500);
    }
});

app.delete('/users/:id', async (req, res) => {
    const userId = req.params.id

    try {
        // Удаляем пост из коллекции 'posts'
        await User.findByIdAndDelete(userId)

        res.sendStatus(204) // Отправляем код 204 No Content, если удаление прошло успешно
    } catch (error) {
        console.error(error)
        res.sendStatus(500) // Отправляем код 500 Internal Server Error в случае ошибки
    }
});

app.ws('/socket', (ws, req) => {
    console.log('WebSocket подключен');

    // Обработка входящих сообщений от клиента
    ws.on('message', (message) => {
        console.log(`Получено сообщение от клиента: ${message}`);

        // Пример обработки входящего сообщения и отправки ответа
        if (message === 'Привет') {
            ws.send('Добрый день!');
            try {
                const message = new Message({
                    chatId: "651b065adb443a61a5720acf",
                    senderId: "641ec3b0431de6ad94c97e70",
                    text: "Добрый день!"
                });
                message.save();
                //res.redirect('/posts');
            } catch (err) {
                console.error(err);
            }
        }else if (message === 'Как дела?'){
            ws.send('Обстановка по кайфу!');
            try {
                const message = new Message({
                    chatId: "651b065adb443a61a5720acf",
                    senderId: "641ec3b0431de6ad94c97e70",
                    text: "Обстановка по кайфу!"
                });
                message.save();
                //res.redirect('/posts');
            } catch (err) {
                console.error(err);
            }
        } else if(message === 'Hello'){
            ws.send('Good day to you!');
            try {
                const message = new Message({
                    chatId: "651b065adb443a61a5720acf",
                    senderId: "641ec3b0431de6ad94c97e70",
                    text: "Good day to you!"
                });
                message.save();
                //res.redirect('/posts');
            } catch (err) {
                console.error(err);
            }
        } else if(message === 'Мне нужна помошь'){
            ws.send('Сочувсвую. Я слишком глуп, чтобы давать советы(');
            try {
                const message = new Message({
                    chatId: "651b065adb443a61a5720acf",
                    senderId: "641ec3b0431de6ad94c97e70",
                    text: "Сочувсвую. Я слишком глуп, чтобы давать советы("
                });
                message.save();
                //res.redirect('/posts');
            } catch (err) {
                console.error(err);
            }
        } else {
            ws.send('А?');
            try {
                const message = new Message({
                    chatId: "651b065adb443a61a5720acf",
                    senderId: "641ec3b0431de6ad94c97e70",
                    text: "А?"
                });
                message.save();
                //res.redirect('/posts');
            } catch (err) {
                console.error(err);
            }
        }
    });

    // Обработка закрытия соединения
    ws.on('close', () => {
        console.log('WebSocket соединение закрыто');
    });
});

// Запускаем сервер на порту 3000
app.listen(3000, () => console.log('Server started...'));