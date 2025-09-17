const { db, auth } = require('../config/firebase');

const register = async (req, res) => {
  try {
    const { email, password, name, phone, role = 'user' } = req.body;

    // Validate input
    if (!email || !password || !name || !phone) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required'
      });
    }

    // Validate role
    const validRoles = ['user', 'driver', 'admin'];
    if (!validRoles.includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid role specified'
      });
    }

    // Create Firebase user
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: name
    });

    // Create user document in Firestore
    const userData = {
      uid: userRecord.uid,
      email,
      name,
      phone,
      role,
      status: role === 'driver' ? 'pending_verification' : 'active',
      avatar: '',
      location: {
        lat: 0,
        lng: 0,
        address: ''
      },
      createdAt: new Date(),
      updatedAt: new Date()
    };

    await db.collection('users').doc(userRecord.uid).set(userData);

    // If driver, create driver profile
    if (role === 'driver') {
      const driverData = {
        userId: userRecord.uid,
        license: { number: '', expiryDate: null, imageUrl: '' },
        vehicle: { type: '', brand: '', model: '', year: null, licensePlate: '', color: '', imageUrl: '' },
        experience: 0,
        status: 'offline',
        currentLocation: { lat: 0, lng: 0 },
        rating: 0,
        totalTrips: 0,
        isVerified: false,
        documents: { identityCard: '', drivingLicense: '', vehicleRegistration: '' },
        createdAt: new Date()
      };

      await db.collection('drivers').doc(userRecord.uid).set(driverData);
    }

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        uid: userRecord.uid,
        email: userData.email,
        name: userData.name,
        role: userData.role
      }
    });

  } catch (error) {
    console.error('Registration error:', error);

    if (error.code === 'auth/email-already-exists') {
      return res.status(400).json({
        success: false,
        message: 'Email already exists'
      });
    }

    if (error.code === 'auth/weak-password') {
      return res.status(400).json({
        success: false,
        message: 'Password should be at least 6 characters'
      });
    }

    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const login = async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: 'ID token is required'
      });
    }

    // Verify the ID token
    const decodedToken = await auth.verifyIdToken(idToken);
    const uid = decodedToken.uid;

    // Get user data from Firestore
    const userDoc = await db.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userData = userDoc.data();

    // Check if user is active
    if (userData.status === 'banned') {
      return res.status(403).json({
        success: false,
        message: 'Account has been banned'
      });
    }

    // If driver, get driver data
    let driverData = null;
    if (userData.role === 'driver') {
      const driverDoc = await db.collection('drivers').doc(uid).get();
      if (driverDoc.exists) {
        driverData = driverDoc.data();
      }
    }

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: userData,
        driver: driverData,
        token: idToken
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(400).json({
      success: false,
      message: 'Invalid token or login failed'
    });
  }
};

module.exports = { register, login };